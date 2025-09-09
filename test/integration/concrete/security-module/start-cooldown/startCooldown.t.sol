// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Errors} from "src/libraries/Errors.sol";
import {ISecurityModule} from "src/interfaces/ISecurityModule.sol";

import {SecurityModule_Integration_Concrete_Test} from "../SecurityModule.t.sol";

contract StartCooldown_Integration_Concrete_Test is SecurityModule_Integration_Concrete_Test {
    function test_RevertGiven_CooldownOngoing() public {
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
        uint256 securityShares1 = securityModule.lock(machineShares1, user1, 0);
        vm.stopPrank();

        // User1 starts cooldown
        vm.startPrank(user1);
        securityModule.startCooldown(securityShares1);

        // User1 tries to start cooldown again
        vm.expectRevert(Errors.CooldownOngoing.selector);
        securityModule.startCooldown(securityShares1);
    }

    function test_RevertWhen_ZeroShares() public {
        vm.startPrank(user3);
        vm.expectRevert(Errors.ZeroShares.selector);
        securityModule.startCooldown(0);
    }

    function test_StartCooldown() public {
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
        vm.prank(user3);
        vm.expectEmit(true, false, false, true, address(securityModule));
        emit ISecurityModule.Cooldown(user3, securitySharesToRedeem, expectedCDMaturity);
        securityModule.startCooldown(securitySharesToRedeem);

        assertEq(securityModule.balanceOf(user3), securityShares1 - securitySharesToRedeem);
        assertEq(securityModule.balanceOf(address(securityModule)), securitySharesToRedeem);

        (uint256 securitySharesCD, uint256 maturity) = securityModule.pendingCooldown(user3);

        assertEq(securitySharesCD, securitySharesToRedeem);
        assertEq(maturity, expectedCDMaturity);
    }

    function test_StartCooldown_Restart() public {
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

        // User3 starts cooldown
        vm.startPrank(user3);
        uint256 expectedCDMaturity = block.timestamp + securityModule.cooldownDuration();
        uint256 securitySharesToRedeem = securityShares1 / 2;
        securityModule.startCooldown(securitySharesToRedeem);

        securityModule.cancelCooldown();

        // User3 restarts cooldown with different amount
        securitySharesToRedeem--;
        vm.expectEmit(true, false, false, true, address(securityModule));
        emit ISecurityModule.Cooldown(user3, securitySharesToRedeem, expectedCDMaturity);
        securityModule.startCooldown(securitySharesToRedeem);

        assertEq(securityModule.balanceOf(user3), securityShares1 - securitySharesToRedeem);
        assertEq(securityModule.balanceOf(address(securityModule)), securitySharesToRedeem);

        (uint256 securitySharesCD, uint256 maturity) = securityModule.pendingCooldown(user3);

        assertEq(securitySharesCD, securitySharesToRedeem);
        assertEq(maturity, expectedCDMaturity);

        skip(1);
        securityModule.cancelCooldown();

        // User3 restarts cooldown later
        expectedCDMaturity = block.timestamp + securityModule.cooldownDuration();
        vm.expectEmit(true, false, false, true, address(securityModule));
        emit ISecurityModule.Cooldown(user3, securitySharesToRedeem, expectedCDMaturity);
        securityModule.startCooldown(securitySharesToRedeem);

        assertEq(securityModule.balanceOf(user3), securityShares1 - securitySharesToRedeem);
        assertEq(securityModule.balanceOf(address(securityModule)), securitySharesToRedeem);

        (securitySharesCD, maturity) = securityModule.pendingCooldown(user3);

        assertEq(securitySharesCD, securitySharesToRedeem);
        assertEq(maturity, expectedCDMaturity);
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
        securityModule.startCooldown(securitySharesToRedeem1);
        (uint256 securitySharesCD1, uint256 maturity1) = securityModule.pendingCooldown(user1);
        assertEq(securitySharesCD1, securitySharesToRedeem1);
        assertEq(maturity1, expectedCDMaturity1);

        // User2 starts cooldown
        vm.prank(user2);
        securityModule.startCooldown(securitySharesToRedeem2);
        (uint256 securitySharesCD2, uint256 maturity2) = securityModule.pendingCooldown(user2);
        assertEq(securitySharesCD2, securitySharesToRedeem2);
        assertEq(maturity2, expectedCDMaturity2);
        (securitySharesCD1, maturity1) = securityModule.pendingCooldown(user1);
        assertEq(securitySharesCD1, securitySharesToRedeem1);
        assertEq(maturity1, expectedCDMaturity1);
    }
}
