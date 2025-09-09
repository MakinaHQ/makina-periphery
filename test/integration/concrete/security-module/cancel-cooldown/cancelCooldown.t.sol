// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Errors} from "src/libraries/Errors.sol";
import {ISecurityModule} from "src/interfaces/ISecurityModule.sol";

import {SecurityModule_Integration_Concrete_Test} from "../SecurityModule.t.sol";

contract CancelCooldown_Integration_Concrete_Test is SecurityModule_Integration_Concrete_Test {
    function test_RevertWhen_NoCooldownOngoing() public {
        vm.startPrank(user3);
        vm.expectRevert(Errors.NoCooldownOngoing.selector);
        securityModule.cancelCooldown();
    }

    function test_CancelCooldown() public {
        uint256 inputAssets1 = 1e18;

        // Deposit assets to the machine
        deal(address(accountingToken), depositorAddr, inputAssets1);
        vm.startPrank(depositorAddr);
        accountingToken.approve(address(machine), inputAssets1);
        uint256 machineShares1 = machine.deposit(inputAssets1, user1, 0);
        vm.stopPrank();

        // User1 locks machine shares
        vm.startPrank(user1);
        machineShare.approve(address(securityModule), machineShares1);
        uint256 securityShares1 = securityModule.lock(machineShares1, user3, 0);
        vm.stopPrank();

        uint256 securitySharesToRedeem = securityShares1 / 2;
        uint256 expectedCDMaturity = block.timestamp + securityModule.cooldownDuration();

        // User3 starts cooldown
        vm.startPrank(user3);
        securityModule.startCooldown(securitySharesToRedeem);

        (uint256 securitySharesCD, uint256 maturity) = securityModule.pendingCooldown(user3);
        assertEq(securitySharesCD, securitySharesToRedeem);
        assertEq(maturity, expectedCDMaturity);

        // User3 cancels cooldown
        vm.expectEmit(true, false, false, true, address(securityModule));
        emit ISecurityModule.CooldownCancelled(user3, securitySharesToRedeem);
        securityModule.cancelCooldown();

        assertEq(securityModule.balanceOf(user3), securityShares1);
        assertEq(securityModule.balanceOf(address(securityModule)), 0);

        (securitySharesCD, maturity) = securityModule.pendingCooldown(user3);
        assertEq(securitySharesCD, 0);
        assertEq(maturity, 0);
    }

    function test_CancelCooldown_TwoUsers() public {
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

        // User2 locks machine shares
        vm.startPrank(user2);
        machineShare.approve(address(securityModule), machineShares2);
        uint256 securityShares2 = securityModule.lock(machineShares2, user2, 0);
        vm.stopPrank();

        uint256 securitySharesToRedeem2 = securityShares2 / 2;
        uint256 expectedCDMaturity2 = block.timestamp + securityModule.cooldownDuration();

        // User1 starts cooldown
        vm.prank(user1);
        securityModule.startCooldown(securitySharesToRedeem1);

        // User2 starts cooldown
        vm.prank(user2);
        securityModule.startCooldown(securitySharesToRedeem2);

        // User1 cancels cooldown
        vm.prank(user1);
        vm.expectEmit(true, false, false, true, address(securityModule));
        emit ISecurityModule.CooldownCancelled(user1, securitySharesToRedeem1);
        securityModule.cancelCooldown();

        assertEq(securityModule.balanceOf(user1), securityShares1);
        assertEq(securityModule.balanceOf(user2), securityShares2 - securitySharesToRedeem2);
        assertEq(securityModule.balanceOf(address(securityModule)), securitySharesToRedeem2);

        (uint256 securitySharesCD1, uint256 maturity1) = securityModule.pendingCooldown(user1);
        assertEq(securitySharesCD1, 0);
        assertEq(maturity1, 0);

        (uint256 securitySharesCD2, uint256 maturity2) = securityModule.pendingCooldown(user2);
        assertEq(securitySharesCD2, securitySharesToRedeem2);
        assertEq(maturity2, expectedCDMaturity2);

        // User2 cancels cooldown
        vm.prank(user2);
        vm.expectEmit(true, false, false, true, address(securityModule));
        emit ISecurityModule.CooldownCancelled(user2, securitySharesToRedeem2);
        securityModule.cancelCooldown();

        assertEq(securityModule.balanceOf(user1), securityShares1);
        assertEq(securityModule.balanceOf(user2), securityShares2);
        assertEq(securityModule.balanceOf(address(securityModule)), 0);

        (securitySharesCD2, maturity2) = securityModule.pendingCooldown(user2);
        assertEq(securitySharesCD2, 0);
        assertEq(maturity2, 0);
    }
}
