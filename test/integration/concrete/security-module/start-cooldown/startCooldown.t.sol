// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {IERC721Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

import {Errors} from "src/libraries/Errors.sol";
import {ISecurityModule} from "src/interfaces/ISecurityModule.sol";

import {SecurityModule_Integration_Concrete_Test} from "../SecurityModule.t.sol";

contract StartCooldown_Integration_Concrete_Test is SecurityModule_Integration_Concrete_Test {
    function test_RevertWhen_ZeroShares() public {
        vm.startPrank(user3);
        vm.expectRevert(Errors.ZeroShares.selector);
        securityModule.startCooldown(0, address(0));
    }

    function test_StartCooldown() public {
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
        uint256 expectedAssets = securityModule.convertToAssets(securitySharesToRedeem);
        uint256 expectedCDMaturity = block.timestamp + securityModule.cooldownDuration();

        uint256 expectedCooldownId = cooldownReceipt.nextTokenId();
        assertEq(expectedCooldownId, 1);

        // User3 starts cooldown
        vm.prank(user3);
        vm.expectEmit(true, true, true, true, address(securityModule));
        emit ISecurityModule.Cooldown(expectedCooldownId, user3, user4, securitySharesToRedeem, expectedCDMaturity);
        (uint256 cooldownId, uint256 maxAssets, uint256 maturity) =
            securityModule.startCooldown(securitySharesToRedeem, user4);

        assertEq(securityModule.balanceOf(user3), securityShares - securitySharesToRedeem);
        assertEq(securityModule.balanceOf(address(securityModule)), securitySharesToRedeem);
        assertEq(cooldownReceipt.balanceOf(user4), 1);
        assertEq(cooldownReceipt.ownerOf(cooldownId), user4);

        assertEq(maxAssets, expectedAssets);
        assertEq(maturity, expectedCDMaturity);
    }

    function test_StartCooldown_SimultaneousCooldowns() public {
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
        uint256 expectedAssets1 = securityModule.convertToAssets(securitySharesToRedeem1);
        uint256 expectedCDMaturity1 = block.timestamp + securityModule.cooldownDuration();

        uint256 expectedCooldownId = cooldownReceipt.nextTokenId();
        assertEq(expectedCooldownId, 1);

        // User3 starts cooldown
        vm.prank(user3);
        vm.expectEmit(true, true, true, true, address(securityModule));
        emit ISecurityModule.Cooldown(expectedCooldownId, user3, user4, securitySharesToRedeem1, expectedCDMaturity1);
        (uint256 cooldownId1, uint256 maxAssets1, uint256 maturity1) =
            securityModule.startCooldown(securitySharesToRedeem1, user4);

        assertEq(maxAssets1, expectedAssets1);
        assertEq(maturity1, expectedCDMaturity1);

        skip(1);

        uint256 securitySharesToRedeem2 = securityShares - securitySharesToRedeem1;
        uint256 expectedAssets2 = securityModule.convertToAssets(securitySharesToRedeem2);
        uint256 expectedCDMaturity2 = block.timestamp + securityModule.cooldownDuration();

        expectedCooldownId = cooldownReceipt.nextTokenId();
        assertEq(expectedCooldownId, 2);

        // User3 starts another cooldown
        vm.prank(user3);
        vm.expectEmit(true, true, true, true, address(securityModule));
        emit ISecurityModule.Cooldown(expectedCooldownId, user3, user4, securitySharesToRedeem2, expectedCDMaturity2);
        (uint256 cooldownId2, uint256 maxAssets2, uint256 maturity2) =
            securityModule.startCooldown(securitySharesToRedeem2, user4);

        assertEq(securityModule.balanceOf(user3), 0);
        assertEq(securityModule.balanceOf(address(securityModule)), securityShares);
        assertEq(cooldownReceipt.balanceOf(user4), 2);
        assertEq(cooldownReceipt.ownerOf(cooldownId1), user4);
        assertEq(cooldownReceipt.ownerOf(cooldownId2), user4);

        assertEq(maxAssets2, expectedAssets2);
        assertEq(maturity2, expectedCDMaturity2);
    }

    function test_StartCooldown_Restart() public {
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

        // User3 starts cooldown
        vm.startPrank(user3);
        uint256 securitySharesToRedeem = securityShares / 2;
        (uint256 cooldownId1,,) = securityModule.startCooldown(securitySharesToRedeem, user3);

        securityModule.cancelCooldown(cooldownId1);

        uint256 expectedCooldownId = cooldownReceipt.nextTokenId();
        assertEq(expectedCooldownId, 2);

        // User3 restarts cooldown with different amount
        securitySharesToRedeem--;
        uint256 expectedCDMaturity = block.timestamp + securityModule.cooldownDuration();
        uint256 expectedAssets = securityModule.convertToAssets(securitySharesToRedeem);
        vm.expectEmit(true, true, true, true, address(securityModule));
        emit ISecurityModule.Cooldown(expectedCooldownId, user3, user3, securitySharesToRedeem, expectedCDMaturity);
        (uint256 cooldownId2, uint256 maxAssets2, uint256 maturity2) =
            securityModule.startCooldown(securitySharesToRedeem, user3);

        assertEq(cooldownId2, expectedCooldownId);
        assertEq(maxAssets2, expectedAssets);
        assertEq(maturity2, expectedCDMaturity);

        assertEq(securityModule.balanceOf(user3), securityShares - securitySharesToRedeem);
        assertEq(securityModule.balanceOf(address(securityModule)), securitySharesToRedeem);

        assertEq(cooldownReceipt.balanceOf(user3), 1);
        assertEq(cooldownReceipt.ownerOf(cooldownId2), user3);

        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, cooldownId1));
        securityModule.pendingCooldown(cooldownId1);

        skip(1);
        securityModule.cancelCooldown(cooldownId2);

        expectedCooldownId = cooldownReceipt.nextTokenId();
        assertEq(expectedCooldownId, 3);

        // User3 restarts cooldown later
        expectedCDMaturity = block.timestamp + securityModule.cooldownDuration();
        vm.expectEmit(true, true, true, true, address(securityModule));
        emit ISecurityModule.Cooldown(expectedCooldownId, user3, user3, securitySharesToRedeem, expectedCDMaturity);
        (uint256 cooldownId3, uint256 maxAssets3, uint256 maturity3) =
            securityModule.startCooldown(securitySharesToRedeem, user3);

        assertEq(cooldownId3, expectedCooldownId);
        assertEq(maxAssets3, expectedAssets);
        assertEq(maturity3, expectedCDMaturity);

        assertEq(securityModule.balanceOf(user3), securityShares - securitySharesToRedeem);
        assertEq(securityModule.balanceOf(address(securityModule)), securitySharesToRedeem);

        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, cooldownId1));
        securityModule.pendingCooldown(cooldownId1);

        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, cooldownId2));
        securityModule.pendingCooldown(cooldownId2);
    }

    function test_StartCooldown_TwoUsers() public {
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

        uint256 securitySharesToRedeem1 = securityShares1 / 2;
        uint256 expectedMaxAssets1 = securityModule.convertToAssets(securitySharesToRedeem1);

        uint256 securitySharesToRedeem2 = securityShares2 / 2;
        uint256 expectedMaxAssets2 = securityModule.convertToAssets(securitySharesToRedeem2);

        uint256 expectedCDMaturity = block.timestamp + securityModule.cooldownDuration();

        // User1 starts cooldown
        vm.prank(user1);
        (uint256 cooldownId1, uint256 maxAssets1, uint256 maturity1) =
            securityModule.startCooldown(securitySharesToRedeem1, user1);
        assertEq(maxAssets1, expectedMaxAssets1);
        assertEq(maturity1, expectedCDMaturity);

        assertEq(cooldownReceipt.balanceOf(user1), 1);
        assertEq(cooldownReceipt.ownerOf(cooldownId1), user1);

        // User2 starts cooldown
        vm.prank(user2);
        (uint256 cooldownId4, uint256 maxAssets4, uint256 maturity4) =
            securityModule.startCooldown(securitySharesToRedeem2, user4);
        assertEq(maxAssets4, expectedMaxAssets2);
        assertEq(maturity4, expectedCDMaturity);

        (uint256 securitySharesCD1, uint256 currentExpectedAssets1, uint256 _maturity1) =
            securityModule.pendingCooldown(cooldownId1);
        assertEq(securitySharesCD1, securitySharesToRedeem1);
        assertEq(currentExpectedAssets1, maxAssets1);
        assertEq(_maturity1, maturity1);

        assertEq(cooldownReceipt.balanceOf(user4), 1);
        assertEq(cooldownReceipt.ownerOf(cooldownId4), user4);

        assertEq(cooldownReceipt.balanceOf(user1), 1);
        assertEq(cooldownReceipt.ownerOf(cooldownId1), user1);
    }
}
