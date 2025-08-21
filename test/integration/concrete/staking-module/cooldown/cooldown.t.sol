// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {IStakingModule} from "src/interfaces/IStakingModule.sol";

import {StakingModule_Integration_Concrete_Test} from "../StakingModule.t.sol";

contract Cooldown_Integration_Concrete_Test is StakingModule_Integration_Concrete_Test {
    function test_Cooldown() public {
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
        uint256 expectedCDMaturity = block.timestamp + stakingModule.cooldownDuration();

        // User3 enters cooldown
        vm.prank(user3);
        vm.expectEmit(true, false, false, true, address(stakingModule));
        emit IStakingModule.Cooldown(user3, stakingSharesToRedeem, expectedCDMaturity);
        stakingModule.cooldown(stakingSharesToRedeem);

        (uint256 stakingSharesCD, uint256 maturity) = stakingModule.pendingCooldown(user3);

        assertEq(stakingSharesCD, stakingSharesToRedeem);
        assertEq(maturity, expectedCDMaturity);
    }

    function test_Cooldown_Override() public {
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

        // User3 enters cooldown
        vm.startPrank(user3);
        uint256 expectedCDMaturity = block.timestamp + stakingModule.cooldownDuration();
        uint256 stakingSharesToRedeem = stakingShares1 / 2;
        stakingModule.cooldown(stakingSharesToRedeem);

        // User3 reenters cooldown with different amount
        stakingSharesToRedeem--;
        vm.expectEmit(true, false, false, true, address(stakingModule));
        emit IStakingModule.Cooldown(user3, stakingSharesToRedeem, expectedCDMaturity);
        stakingModule.cooldown(stakingSharesToRedeem);

        (uint256 stakingSharesCD, uint256 maturity) = stakingModule.pendingCooldown(user3);

        assertEq(stakingSharesCD, stakingSharesToRedeem);
        assertEq(maturity, expectedCDMaturity);

        skip(1);

        // User3 reenters cooldown later
        expectedCDMaturity = block.timestamp + stakingModule.cooldownDuration();
        vm.expectEmit(true, false, false, true, address(stakingModule));
        emit IStakingModule.Cooldown(user3, stakingSharesToRedeem, expectedCDMaturity);
        stakingModule.cooldown(stakingSharesToRedeem);

        (stakingSharesCD, maturity) = stakingModule.pendingCooldown(user3);

        assertEq(stakingSharesCD, stakingSharesToRedeem);
        assertEq(maturity, expectedCDMaturity);
    }
}
