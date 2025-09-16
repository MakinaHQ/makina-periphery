// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {IERC721Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

import {Errors} from "src/libraries/Errors.sol";

import {SecurityModule_Integration_Concrete_Test} from "../SecurityModule.t.sol";

contract PendingCooldown_Integration_Concrete_Test is SecurityModule_Integration_Concrete_Test {
    function test_RevertWhen_ZeroShares() public {
        vm.startPrank(user3);
        vm.expectRevert(Errors.ZeroShares.selector);
        securityModule.startCooldown(0, address(0));
    }

    function test_PendingCooldown() public {
        uint256 inputAssets = 1e18;

        // Deposit assets to the machine
        deal(address(accountingToken), depositorAddr, inputAssets);
        vm.startPrank(depositorAddr);
        accountingToken.approve(address(machine), inputAssets);
        uint256 machineShares = machine.deposit(inputAssets, user1, 0);
        vm.stopPrank();

        // User1 locks machine shares
        vm.startPrank(user1);
        machineShare.approve(address(securityModule), machineShares);
        uint256 securityShares = securityModule.lock(machineShares, user3, 0);
        vm.stopPrank();

        uint256 securitySharesToRedeem = securityShares / 2;

        uint256 expectedCooldownId = cooldownReceipt.nextTokenId();
        assertEq(expectedCooldownId, 1);

        // User3 starts cooldown
        vm.prank(user3);
        (uint256 cooldownId1, uint256 maxAssets, uint256 maturity) =
            securityModule.startCooldown(securitySharesToRedeem, user4);

        (uint256 securitySharesCD, uint256 currentExpectedAssets, uint256 _maturity) =
            securityModule.pendingCooldown(cooldownId1);

        assertEq(securitySharesCD, securitySharesToRedeem);
        assertEq(currentExpectedAssets, maxAssets);
        assertEq(_maturity, maturity);
    }

    function test_PendingCooldown_NegativeYield() public {
        uint256 inputAssets = 1e18;

        // Deposit assets to the machine
        deal(address(accountingToken), depositorAddr, inputAssets);
        vm.startPrank(depositorAddr);
        accountingToken.approve(address(machine), inputAssets);
        uint256 machineShares = machine.deposit(inputAssets, user1, 0);
        vm.stopPrank();

        // User1 locks machine shares
        vm.startPrank(user1);
        machineShare.approve(address(securityModule), machineShares);
        uint256 securityShares = securityModule.lock(machineShares, user3, 0);
        vm.stopPrank();

        uint256 securitySharesToRedeem = securityShares / 2;

        uint256 expectedCooldownId = cooldownReceipt.nextTokenId();
        assertEq(expectedCooldownId, 1);

        // User3 starts cooldown
        vm.prank(user3);
        (uint256 cooldownId1, uint256 maxAssets, uint256 maturity) =
            securityModule.startCooldown(securitySharesToRedeem, user4);

        // negatve yield occurs through slashing
        vm.prank(securityCouncil);
        securityModule.slash(1e17);

        uint256 currentAssets = securityModule.convertToAssets(securitySharesToRedeem);
        assertLt(currentAssets, maxAssets);

        (uint256 securitySharesCD, uint256 currentExpectedAssets, uint256 _maturity) =
            securityModule.pendingCooldown(cooldownId1);

        assertEq(securitySharesCD, securitySharesToRedeem);
        assertEq(currentExpectedAssets, currentAssets);
        assertEq(_maturity, maturity);
    }

    function test_PendingCooldown_SimultaneousCooldowns() public {
        uint256 inputAssets = 1e18;

        // Deposit assets to the machine
        deal(address(accountingToken), depositorAddr, inputAssets);
        vm.startPrank(depositorAddr);
        accountingToken.approve(address(machine), inputAssets);
        uint256 machineShares = machine.deposit(inputAssets, user1, 0);
        vm.stopPrank();

        // User1 locks machine shares
        vm.startPrank(user1);
        machineShare.approve(address(securityModule), machineShares);
        uint256 securityShares = securityModule.lock(machineShares, user3, 0);
        vm.stopPrank();

        uint256 securitySharesToRedeem1 = securityShares / 2;

        // User3 starts cooldown
        vm.prank(user3);
        (uint256 cooldownId1, uint256 maxAssets1, uint256 maturity1) =
            securityModule.startCooldown(securitySharesToRedeem1, user4);

        (uint256 securitySharesCD1, uint256 currentExpectedAssets1, uint256 _maturity1) =
            securityModule.pendingCooldown(cooldownId1);
        assertEq(securitySharesCD1, securitySharesToRedeem1);
        assertEq(currentExpectedAssets1, maxAssets1);
        assertEq(_maturity1, maturity1);

        skip(1);

        // User3 starts another cooldown
        uint256 securitySharesToRedeem2 = securityShares - securitySharesToRedeem1;
        vm.prank(user3);
        (uint256 cooldownId2, uint256 maxAssets2, uint256 maturity2) =
            securityModule.startCooldown(securitySharesToRedeem2, user4);

        (uint256 securitySharesCD2, uint256 currentExpectedAssets2, uint256 _maturity2) =
            securityModule.pendingCooldown(cooldownId2);
        assertEq(securitySharesCD2, securitySharesToRedeem2);
        assertEq(currentExpectedAssets2, maxAssets2);
        assertEq(_maturity2, maturity2);
    }

    function test_PendingCooldown_Restart() public {
        uint256 inputAssets = 1e18;

        // Deposit assets to the machine
        deal(address(accountingToken), depositorAddr, inputAssets);
        vm.startPrank(depositorAddr);
        accountingToken.approve(address(machine), inputAssets);
        uint256 machineShares = machine.deposit(inputAssets, user1, 0);
        vm.stopPrank();

        // User1 locks machine shares
        vm.startPrank(user1);
        machineShare.approve(address(securityModule), machineShares);
        uint256 securityShares = securityModule.lock(machineShares, user3, 0);
        vm.stopPrank();

        // User3 starts cooldown1
        vm.startPrank(user3);
        uint256 securitySharesToRedeem = securityShares / 2;
        (uint256 cooldownId1,,) = securityModule.startCooldown(securitySharesToRedeem, user3);

        // User3 cancels cooldown1
        securityModule.cancelCooldown(cooldownId1);

        // User3 restarts cooldown with different amount
        securitySharesToRedeem--;
        (uint256 cooldownId2, uint256 maxAssets2, uint256 maturity2) =
            securityModule.startCooldown(securitySharesToRedeem, user3);

        (uint256 securitySharesCD2, uint256 currentExpectedAssets2, uint256 _maturity2) =
            securityModule.pendingCooldown(cooldownId2);
        assertEq(securitySharesCD2, securitySharesToRedeem);
        assertEq(currentExpectedAssets2, maxAssets2);
        assertEq(_maturity2, maturity2);

        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, cooldownId1));
        securityModule.pendingCooldown(cooldownId1);

        // User3 cancels cooldown2
        securityModule.cancelCooldown(cooldownId2);

        // User3 restarts cooldown later
        skip(1);
        (uint256 cooldownId3, uint256 maxAssets3, uint256 maturity3) =
            securityModule.startCooldown(securitySharesToRedeem, user3);

        (uint256 securitySharesCD3, uint256 currentExpectedAssets3, uint256 _maturity3) =
            securityModule.pendingCooldown(cooldownId3);
        assertEq(securitySharesCD3, securitySharesToRedeem);
        assertEq(currentExpectedAssets3, maxAssets3);
        assertEq(_maturity3, maturity3);

        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, cooldownId1));
        securityModule.pendingCooldown(cooldownId1);

        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, cooldownId2));
        securityModule.pendingCooldown(cooldownId2);
    }

    function test_PendingCooldown_TwoUsers() public {
        uint256 inputAssets1 = 1e18;
        uint256 inputAssets2 = 2e18;

        // Deposit assets to the machine
        deal(address(accountingToken), depositorAddr, inputAssets1 + inputAssets2);
        vm.startPrank(depositorAddr);
        accountingToken.approve(address(machine), inputAssets1 + inputAssets2);
        uint256 machineShares1 = machine.deposit(inputAssets1, user1, 0);
        uint256 machineShares2 = machine.deposit(inputAssets2, user2, 0);
        vm.stopPrank();

        // User1 locks machine shares
        vm.startPrank(user1);
        machineShare.approve(address(securityModule), machineShares1);
        uint256 securityShares1 = securityModule.lock(machineShares1, user1, 0);
        vm.stopPrank();

        // User2 locks machine shares
        vm.startPrank(user2);
        machineShare.approve(address(securityModule), machineShares2);
        uint256 securityShares2 = securityModule.lock(machineShares2, user2, 0);
        vm.stopPrank();

        // User1 starts cooldown
        uint256 securitySharesToRedeem1 = securityShares1 / 2;
        vm.prank(user1);
        (uint256 cooldownId1, uint256 maxAssets1, uint256 maturity1) =
            securityModule.startCooldown(securitySharesToRedeem1, user1);

        (uint256 securitySharesCD1, uint256 currentExpectedAssets1, uint256 _maturity1) =
            securityModule.pendingCooldown(cooldownId1);
        assertEq(securitySharesCD1, securitySharesToRedeem1);
        assertEq(currentExpectedAssets1, maxAssets1);
        assertEq(_maturity1, maturity1);

        // User2 starts cooldown
        uint256 securitySharesToRedeem2 = securityShares2 / 2;
        vm.prank(user2);
        (uint256 cooldownId4, uint256 maxAssets4, uint256 maturity4) =
            securityModule.startCooldown(securitySharesToRedeem2, user4);

        (uint256 securitySharesCD4, uint256 currentExpectedAssets4, uint256 _maturity4) =
            securityModule.pendingCooldown(cooldownId4);
        assertEq(securitySharesCD4, securitySharesToRedeem2);
        assertEq(currentExpectedAssets4, maxAssets4);
        assertEq(_maturity4, maturity4);
    }
}
