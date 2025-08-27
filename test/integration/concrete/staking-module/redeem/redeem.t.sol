// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {IStakingModule} from "src/interfaces/IStakingModule.sol";
import {Errors, CoreErrors} from "src/libraries/Errors.sol";

import {StakingModule_Integration_Concrete_Test} from "../StakingModule.t.sol";

contract Redeem_Integration_Concrete_Test is StakingModule_Integration_Concrete_Test {
    function test_RevertGiven_CooldownOngoing() public {
        uint256 inputAssets1 = 1e18;

        // Deposit assets to the machine
        deal(address(accountingToken), depositorAddr, inputAssets1);
        vm.startPrank(depositorAddr);
        accountingToken.approve(address(machine), inputAssets1);
        uint256 machineShares1 = machine.deposit(inputAssets1, user1, 0);
        vm.stopPrank();

        // User1 stakes machine shares
        vm.startPrank(user1);
        machineShare.approve(address(stakingModule), machineShares1);
        uint256 stakingShares1 = stakingModule.stake(machineShares1, user3, 0);
        vm.stopPrank();

        uint256 stakingSharesToRedeem = stakingShares1 / 2;

        // User3 starts cooldown
        vm.prank(user3);
        stakingModule.startCooldown(stakingSharesToRedeem);

        skip(stakingModule.cooldownDuration() - 1);

        vm.expectRevert(Errors.CooldownOngoing.selector);
        vm.prank(user3);
        stakingModule.redeem(user4, 0);
    }

    function test_RevertGiven_SlippageProtectionTriggered() public {
        uint256 inputAssets1 = 1e18;

        // Deposit assets to the machine
        deal(address(accountingToken), depositorAddr, inputAssets1);
        vm.startPrank(depositorAddr);
        accountingToken.approve(address(machine), inputAssets1);
        uint256 machineShares1 = machine.deposit(inputAssets1, user1, 0);
        vm.stopPrank();

        // User1 stakes machine shares
        vm.startPrank(user1);
        machineShare.approve(address(stakingModule), machineShares1);
        uint256 stakingShares1 = stakingModule.stake(machineShares1, user3, 0);
        vm.stopPrank();

        uint256 stakingSharesToRedeem = stakingShares1 / 2;

        // User3 starts cooldown
        vm.prank(user3);
        stakingModule.startCooldown(stakingSharesToRedeem);

        skip(stakingModule.cooldownDuration());

        uint256 expectedMachineShares = stakingModule.convertToAssets(stakingSharesToRedeem);

        vm.expectRevert(CoreErrors.SlippageProtection.selector);
        vm.prank(user3);
        stakingModule.redeem(user4, expectedMachineShares + 1);
    }

    function test_Redeem() public {
        uint256 inputAssets1 = 1e18;

        // Deposit assets to the machine
        deal(address(accountingToken), depositorAddr, inputAssets1);
        vm.startPrank(depositorAddr);
        accountingToken.approve(address(machine), inputAssets1);
        uint256 machineShares1 = machine.deposit(inputAssets1, user1, 0);
        vm.stopPrank();

        // User1 stakes machine shares
        vm.startPrank(user1);
        machineShare.approve(address(stakingModule), machineShares1);
        uint256 stakingShares1 = stakingModule.stake(machineShares1, user3, 0);
        vm.stopPrank();

        uint256 stakingSharesToRedeem = stakingShares1 / 2;

        // User3 starts cooldown
        vm.prank(user3);
        stakingModule.startCooldown(stakingSharesToRedeem);

        skip(stakingModule.cooldownDuration());

        uint256 expectedMachineShares = stakingModule.convertToAssets(stakingSharesToRedeem);

        // User3 redeems staking shares
        vm.expectEmit(true, false, false, true, address(stakingModule));
        emit IStakingModule.Redeem(user3, user4, expectedMachineShares, stakingSharesToRedeem);
        vm.prank(user3);
        stakingModule.redeem(user4, expectedMachineShares);

        assertEq(stakingModule.balanceOf(user3), stakingShares1 - stakingSharesToRedeem);
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

        // User1 stakes machine shares
        vm.startPrank(user1);
        machineShare.approve(address(stakingModule), machineShares1);
        uint256 stakingShares1 = stakingModule.stake(machineShares1, user3, 0);
        vm.stopPrank();

        uint256 stakingSharesToRedeem = stakingShares1 / 2;

        // User3 starts cooldown
        vm.prank(user3);
        stakingModule.startCooldown(stakingSharesToRedeem);

        skip(stakingModule.cooldownDuration());

        // get rate before yield
        uint256 expectedMachineShares = stakingModule.convertToAssets(stakingSharesToRedeem);

        // generate positive yield
        deal(address(machineShare), address(stakingModule), machineShares1 + yieldAmount);

        // User3 redeems staking shares
        vm.expectEmit(true, false, false, true, address(stakingModule));
        emit IStakingModule.Redeem(user3, user4, expectedMachineShares, stakingSharesToRedeem);
        vm.prank(user3);
        stakingModule.redeem(user4, expectedMachineShares);

        assertEq(stakingModule.balanceOf(user3), stakingShares1 - stakingSharesToRedeem);
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

        // User1 stakes machine shares
        vm.startPrank(user1);
        machineShare.approve(address(stakingModule), machineShares1);
        uint256 stakingShares1 = stakingModule.stake(machineShares1, user3, 0);
        vm.stopPrank();

        uint256 stakingSharesToRedeem = stakingShares1 / 2;

        // User3 starts cooldown
        vm.prank(user3);
        stakingModule.startCooldown(stakingSharesToRedeem);

        skip(stakingModule.cooldownDuration());

        // generate negative yield
        deal(address(machineShare), address(stakingModule), machineShares1 - yieldAmount);

        // get rate after yield
        uint256 expectedMachineShares = stakingModule.convertToAssets(stakingSharesToRedeem);

        // User3 redeems staking shares
        vm.expectEmit(true, false, false, true, address(stakingModule));
        emit IStakingModule.Redeem(user3, user4, expectedMachineShares, stakingSharesToRedeem);
        vm.prank(user3);
        stakingModule.redeem(user4, expectedMachineShares);

        assertEq(stakingModule.balanceOf(user3), stakingShares1 - stakingSharesToRedeem);
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

        // User1 stakes machine shares
        vm.startPrank(user1);
        machineShare.approve(address(stakingModule), machineShares1);
        uint256 stakingShares1 = stakingModule.stake(machineShares1, user3, 0);
        vm.stopPrank();

        // User2 stakes machine shares
        vm.startPrank(user2);
        machineShare.approve(address(stakingModule), machineShares2);
        uint256 stakingShares2 = stakingModule.stake(machineShares2, user4, 0);
        vm.stopPrank();

        // User3 starts cooldown
        vm.prank(user3);
        stakingModule.startCooldown(stakingShares1);
        uint256 previewRedeem1 = stakingModule.previewStake(stakingShares1);

        skip(usersDelay);

        // generate positive yield
        deal(address(machineShare), address(stakingModule), machineShares1 + machineShares2 + yieldAmount);

        // User4 starts cooldown
        vm.prank(user4);
        stakingModule.startCooldown(stakingShares2);

        // generate negative yield
        deal(address(machineShare), address(stakingModule), machineShares1 + machineShares2);

        uint256 previewRedeem2 = stakingModule.previewStake(stakingShares2);

        skip(stakingModule.cooldownDuration() - usersDelay);

        // User3 redeems staking shares
        vm.expectEmit(true, false, false, true, address(stakingModule));
        emit IStakingModule.Redeem(user3, user3, previewRedeem1, stakingShares1);
        vm.prank(user3);
        stakingModule.redeem(user3, 0);

        assertEq(stakingModule.balanceOf(user3), 0);
        assertEq(machineShare.balanceOf(user3), previewRedeem1);

        // User4 tries redeeming staking shares before cooldown maturity
        vm.expectRevert(Errors.CooldownOngoing.selector);
        vm.prank(user4);
        stakingModule.redeem(user4, 0);

        skip(usersDelay);

        // User4 redeems staking shares
        vm.expectEmit(true, false, false, true, address(stakingModule));
        emit IStakingModule.Redeem(user4, user4, previewRedeem2, stakingShares2);
        vm.prank(user4);
        stakingModule.redeem(user4, 0);

        assertEq(stakingModule.balanceOf(user4), 0);
        assertEq(machineShare.balanceOf(user4), previewRedeem2);
    }
}
