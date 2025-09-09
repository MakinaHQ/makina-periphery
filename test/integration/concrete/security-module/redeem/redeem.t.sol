// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {ISecurityModule} from "src/interfaces/ISecurityModule.sol";
import {Errors, CoreErrors} from "src/libraries/Errors.sol";

import {SecurityModule_Integration_Concrete_Test} from "../SecurityModule.t.sol";

contract Redeem_Integration_Concrete_Test is SecurityModule_Integration_Concrete_Test {
    function test_RevertGiven_NoCooldownOngoing() public {
        vm.expectRevert(Errors.NoCooldownOngoing.selector);
        securityModule.redeem(address(0), 0);
    }

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
        uint256 securityShares1 = securityModule.lock(machineShares1, user3, 0);
        vm.stopPrank();

        uint256 securitySharesToRedeem = securityShares1 / 2;

        // User3 starts cooldown
        vm.prank(user3);
        securityModule.startCooldown(securitySharesToRedeem);

        skip(securityModule.cooldownDuration() - 1);

        vm.expectRevert(Errors.CooldownOngoing.selector);
        vm.prank(user3);
        securityModule.redeem(user4, 0);
    }

    function test_RevertGiven_SlippageProtectionTriggered() public {
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

        // User3 starts cooldown
        vm.prank(user3);
        securityModule.startCooldown(securitySharesToRedeem);

        skip(securityModule.cooldownDuration());

        uint256 expectedMachineShares = securityModule.convertToAssets(securitySharesToRedeem);

        vm.expectRevert(CoreErrors.SlippageProtection.selector);
        vm.prank(user3);
        securityModule.redeem(user4, expectedMachineShares + 1);
    }

    function test_Redeem() public {
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

        // User3 starts cooldown
        vm.prank(user3);
        securityModule.startCooldown(securitySharesToRedeem);

        skip(securityModule.cooldownDuration());

        uint256 expectedMachineShares = securityModule.convertToAssets(securitySharesToRedeem);

        // User3 redeems security shares
        vm.expectEmit(true, false, false, true, address(securityModule));
        emit ISecurityModule.Redeem(user3, user4, expectedMachineShares, securitySharesToRedeem);
        vm.prank(user3);
        securityModule.redeem(user4, expectedMachineShares);

        assertEq(securityModule.balanceOf(user3), securityShares1 - securitySharesToRedeem);
        assertEq(machineShare.balanceOf(user4), expectedMachineShares);
    }

    function test_Redeem_PositiveYield() public {
        uint256 inputAssets1 = 1e18;
        uint256 yieldAmount = 2e17;

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

        // User3 starts cooldown
        vm.prank(user3);
        securityModule.startCooldown(securitySharesToRedeem);

        skip(securityModule.cooldownDuration());

        // get rate before yield
        uint256 expectedMachineShares = securityModule.convertToAssets(securitySharesToRedeem);

        // generate positive yield
        deal(address(machineShare), address(securityModule), machineShares1 + yieldAmount);

        // User3 redeems security shares
        vm.expectEmit(true, false, false, true, address(securityModule));
        emit ISecurityModule.Redeem(user3, user4, expectedMachineShares, securitySharesToRedeem);
        vm.prank(user3);
        securityModule.redeem(user4, expectedMachineShares);

        assertEq(securityModule.balanceOf(user3), securityShares1 - securitySharesToRedeem);
        assertEq(machineShare.balanceOf(user4), expectedMachineShares);
    }

    function test_Redeem_NegativeYield() public {
        uint256 inputAssets1 = 1e18;
        uint256 yieldAmount = 2e17;

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

        // User3 starts cooldown
        vm.prank(user3);
        securityModule.startCooldown(securitySharesToRedeem);

        skip(securityModule.cooldownDuration());

        // generate negative yield
        deal(address(machineShare), address(securityModule), machineShares1 - yieldAmount);

        // get rate after yield
        uint256 expectedMachineShares = securityModule.convertToAssets(securitySharesToRedeem);

        // User3 redeems security shares
        vm.expectEmit(true, false, false, true, address(securityModule));
        emit ISecurityModule.Redeem(user3, user4, expectedMachineShares, securitySharesToRedeem);
        vm.prank(user3);
        securityModule.redeem(user4, expectedMachineShares);

        assertEq(securityModule.balanceOf(user3), securityShares1 - securitySharesToRedeem);
        assertEq(machineShare.balanceOf(user4), expectedMachineShares);
    }

    function test_Redeem_TwoUsers() public {
        uint256 inputAssets1 = 1e18;
        uint256 inputAssets2 = 2e18;

        uint256 yieldAmount = 2e17;

        uint256 usersDelay = 1 hours;

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
        uint256 securityShares1 = securityModule.lock(machineShares1, user3, 0);
        vm.stopPrank();

        // User2 locks machine shares
        vm.startPrank(user2);
        machineShare.approve(address(securityModule), machineShares2);
        uint256 securityShares2 = securityModule.lock(machineShares2, user4, 0);
        vm.stopPrank();

        // User3 starts cooldown
        vm.prank(user3);
        securityModule.startCooldown(securityShares1);
        uint256 previewRedeem1 = securityModule.previewLock(securityShares1);

        skip(usersDelay);

        // generate positive yield
        deal(address(machineShare), address(securityModule), machineShares1 + machineShares2 + yieldAmount);

        // User4 starts cooldown
        vm.prank(user4);
        securityModule.startCooldown(securityShares2);

        // generate negative yield
        deal(address(machineShare), address(securityModule), machineShares1 + machineShares2);

        uint256 previewRedeem2 = securityModule.previewLock(securityShares2);

        skip(securityModule.cooldownDuration() - usersDelay);

        // User3 redeems security shares
        vm.expectEmit(true, false, false, true, address(securityModule));
        emit ISecurityModule.Redeem(user3, user3, previewRedeem1, securityShares1);
        vm.prank(user3);
        securityModule.redeem(user3, 0);

        assertEq(securityModule.balanceOf(user3), 0);
        assertEq(machineShare.balanceOf(user3), previewRedeem1);

        // User4 tries redeeming security shares before cooldown maturity
        vm.expectRevert(Errors.CooldownOngoing.selector);
        vm.prank(user4);
        securityModule.redeem(user4, 0);

        skip(usersDelay);

        // User4 redeems security shares
        vm.expectEmit(true, false, false, true, address(securityModule));
        emit ISecurityModule.Redeem(user4, user4, previewRedeem2, securityShares2);
        vm.prank(user4);
        securityModule.redeem(user4, 0);

        assertEq(securityModule.balanceOf(user4), 0);
        assertEq(machineShare.balanceOf(user4), previewRedeem2);
    }
}
