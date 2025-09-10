// SPDX-License-Identifier: UNLICENSED
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
        uint256 expectedCDMaturity = block.timestamp + securityModule.cooldownDuration();

        uint256 expectedCooldownId = cooldownReceipt.nextTokenId();
        assertEq(expectedCooldownId, 1);

        // User3 starts cooldown
        vm.prank(user3);
        vm.expectEmit(true, true, true, true, address(securityModule));
        emit ISecurityModule.Cooldown(expectedCooldownId, user3, user4, securitySharesToRedeem, expectedCDMaturity);
        (uint256 cooldownId,) = securityModule.startCooldown(securitySharesToRedeem, user4);

        assertEq(securityModule.balanceOf(user3), securityShares - securitySharesToRedeem);
        assertEq(securityModule.balanceOf(address(securityModule)), securitySharesToRedeem);
        assertEq(cooldownReceipt.balanceOf(user4), 1);
        assertEq(cooldownReceipt.ownerOf(cooldownId), user4);

        (uint256 securitySharesCD, uint256 maturity) = securityModule.pendingCooldown(cooldownId);

        assertEq(securitySharesCD, securitySharesToRedeem);
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
        uint256 expectedCDMaturity1 = block.timestamp + securityModule.cooldownDuration();

        uint256 expectedCooldownId = cooldownReceipt.nextTokenId();
        assertEq(expectedCooldownId, 1);

        // User3 starts cooldown
        vm.prank(user3);
        vm.expectEmit(true, true, true, true, address(securityModule));
        emit ISecurityModule.Cooldown(expectedCooldownId, user3, user4, securitySharesToRedeem1, expectedCDMaturity1);
        (uint256 cooldownId1,) = securityModule.startCooldown(securitySharesToRedeem1, user4);

        skip(1);

        uint256 securitySharesToRedeem2 = securityShares - securitySharesToRedeem1;
        uint256 expectedCDMaturity2 = block.timestamp + securityModule.cooldownDuration();

        expectedCooldownId = cooldownReceipt.nextTokenId();
        assertEq(expectedCooldownId, 2);

        // User3 starts another cooldown
        vm.prank(user3);
        vm.expectEmit(true, true, true, true, address(securityModule));
        emit ISecurityModule.Cooldown(expectedCooldownId, user3, user4, securitySharesToRedeem2, expectedCDMaturity2);
        (uint256 cooldownId2,) = securityModule.startCooldown(securitySharesToRedeem2, user4);

        assertEq(securityModule.balanceOf(user3), 0);
        assertEq(securityModule.balanceOf(address(securityModule)), securityShares);
        assertEq(cooldownReceipt.balanceOf(user4), 2);
        assertEq(cooldownReceipt.ownerOf(cooldownId1), user4);
        assertEq(cooldownReceipt.ownerOf(cooldownId2), user4);

        (uint256 securitySharesCD1, uint256 maturity1) = securityModule.pendingCooldown(cooldownId1);

        assertEq(securitySharesCD1, securitySharesToRedeem1);
        assertEq(maturity1, expectedCDMaturity1);

        (uint256 securitySharesCD2, uint256 maturity2) = securityModule.pendingCooldown(cooldownId2);

        assertEq(securitySharesCD2, securitySharesToRedeem2);
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
        uint256 expectedCDMaturity = block.timestamp + securityModule.cooldownDuration();
        uint256 securitySharesToRedeem = securityShares / 2;
        (uint256 cooldownId1,) = securityModule.startCooldown(securitySharesToRedeem, user3);

        securityModule.cancelCooldown(cooldownId1);

        uint256 expectedCooldownId = cooldownReceipt.nextTokenId();
        assertEq(expectedCooldownId, 2);

        // User3 restarts cooldown with different amount
        securitySharesToRedeem--;
        vm.expectEmit(true, true, true, true, address(securityModule));
        emit ISecurityModule.Cooldown(expectedCooldownId, user3, user3, securitySharesToRedeem, expectedCDMaturity);
        (uint256 cooldownId2,) = securityModule.startCooldown(securitySharesToRedeem, user3);

        assertEq(cooldownId2, expectedCooldownId);

        assertEq(securityModule.balanceOf(user3), securityShares - securitySharesToRedeem);
        assertEq(securityModule.balanceOf(address(securityModule)), securitySharesToRedeem);

        (uint256 securitySharesCD, uint256 maturity) = securityModule.pendingCooldown(cooldownId2);

        assertEq(securitySharesCD, securitySharesToRedeem);
        assertEq(maturity, expectedCDMaturity);

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
        (uint256 cooldownId3,) = securityModule.startCooldown(securitySharesToRedeem, user3);

        assertEq(cooldownId3, expectedCooldownId);

        assertEq(securityModule.balanceOf(user3), securityShares - securitySharesToRedeem);
        assertEq(securityModule.balanceOf(address(securityModule)), securitySharesToRedeem);

        (securitySharesCD, maturity) = securityModule.pendingCooldown(cooldownId3);

        assertEq(securitySharesCD, securitySharesToRedeem);
        assertEq(maturity, expectedCDMaturity);

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

        uint256 securitySharesToRedeem1 = securityShares1 / 2;
        uint256 expectedCDMaturity1 = block.timestamp + securityModule.cooldownDuration();

        // User2 locks machine shares
        vm.startPrank(user2);
        machineShare.approve(address(securityModule), machineShares2);
        uint256 securityShares2 = securityModule.lock(machineShares2, user2, 0);
        vm.stopPrank();

        uint256 securitySharesToRedeem2 = securityShares2 / 2;
        uint256 expectedCDMaturity2 = block.timestamp + securityModule.cooldownDuration();

        // User1 starts cooldown
        vm.prank(user1);
        (uint256 cooldownId1,) = securityModule.startCooldown(securitySharesToRedeem1, user1);
        (uint256 securitySharesCD1, uint256 maturity1) = securityModule.pendingCooldown(cooldownId1);
        assertEq(securitySharesCD1, securitySharesToRedeem1);
        assertEq(maturity1, expectedCDMaturity1);

        assertEq(cooldownReceipt.balanceOf(user1), 1);
        assertEq(cooldownReceipt.ownerOf(cooldownId1), user1);

        // User2 starts cooldown
        vm.prank(user2);
        (uint256 cooldownId4,) = securityModule.startCooldown(securitySharesToRedeem2, user4);
        (uint256 securitySharesCD4, uint256 maturity4) = securityModule.pendingCooldown(cooldownId4);
        assertEq(securitySharesCD4, securitySharesToRedeem2);
        assertEq(maturity4, expectedCDMaturity2);
        (securitySharesCD1, maturity1) = securityModule.pendingCooldown(cooldownId1);
        assertEq(securitySharesCD1, securitySharesToRedeem1);
        assertEq(maturity1, expectedCDMaturity1);

        assertEq(cooldownReceipt.balanceOf(user4), 1);
        assertEq(cooldownReceipt.ownerOf(cooldownId4), user4);

        assertEq(cooldownReceipt.balanceOf(user1), 1);
        assertEq(cooldownReceipt.ownerOf(cooldownId1), user1);
    }
}
