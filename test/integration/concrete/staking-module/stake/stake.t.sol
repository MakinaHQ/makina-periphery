// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {IStakingModule} from "src/interfaces/IStakingModule.sol";
import {Errors, CoreErrors} from "src/libraries/Errors.sol";

import {StakingModule_Integration_Concrete_Test} from "../StakingModule.t.sol";

contract Stake_Integration_Concrete_Test is StakingModule_Integration_Concrete_Test {
    function test_RevertGiven_SlashingSettlementOngoing() public {
        vm.prank(securityCouncil);
        stakingModule.slash(0);

        vm.expectRevert(Errors.SlashingSettlementOngoing.selector);
        stakingModule.stake(0, address(0), 0);
    }

    function test_RevertGiven_SlippageProtectionTriggered() public {
        uint256 inputAssets1 = 1e18;

        // Deposit assets to the machine
        deal(address(accountingToken), machineDepositorAddr, inputAssets1);
        vm.startPrank(machineDepositorAddr);
        accountingToken.approve(address(machine), inputAssets1);
        uint256 shares1 = machine.deposit(inputAssets1, user1, 0);
        vm.stopPrank();

        uint256 previewStake = stakingModule.previewStake(shares1);

        // User1 tries staking machine shares with slippage protection too high
        vm.startPrank(user1);
        machineShare.approve(address(stakingModule), shares1);
        vm.expectRevert(CoreErrors.SlippageProtection.selector);
        stakingModule.stake(shares1, user1, previewStake + 1);
    }

    function test_Stake() public {
        uint256 inputAssets1 = 1e18;

        // Deposit assets to the machine
        deal(address(accountingToken), machineDepositorAddr, inputAssets1);
        vm.startPrank(machineDepositorAddr);
        accountingToken.approve(address(machine), inputAssets1);
        uint256 machineShares1 = machine.deposit(inputAssets1, user1, 0);
        vm.stopPrank();

        uint256 previewStake = stakingModule.previewStake(machineShares1);

        // User1 stakes machine shares
        vm.startPrank(user1);
        machineShare.approve(address(stakingModule), machineShares1);
        vm.expectEmit(true, true, false, true, address(stakingModule));
        emit IStakingModule.Stake(user1, user3, machineShares1, previewStake);
        stakingModule.stake(machineShares1, user3, previewStake);
        vm.stopPrank();

        assertEq(machineShare.balanceOf(user1), 0);
        assertEq(machineShare.balanceOf(address(stakingModule)), machineShares1);
        assertEq(stakingModule.balanceOf(user3), previewStake);
        assertEq(stakingModule.totalStakedAmount(), machineShares1);
    }
}
