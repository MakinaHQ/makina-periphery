// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {IStakingModule} from "src/interfaces/IStakingModule.sol";
import {Errors, CoreErrors} from "src/libraries/Errors.sol";

import {StakingModule_Integration_Concrete_Test} from "../StakingModule.t.sol";

contract Slash_Integration_Concrete_Test is StakingModule_Integration_Concrete_Test {
    uint256 private machineShares;

    function setUp() public override {
        StakingModule_Integration_Concrete_Test.setUp();

        // Deposit assets to the machine
        uint256 inputAssets = 3 * DEFAULT_MIN_BALANCE_AFTER_SLASH;
        deal(address(accountingToken), depositorAddr, inputAssets);
        vm.startPrank(depositorAddr);
        accountingToken.approve(address(machine), inputAssets);
        machineShares = machine.deposit(inputAssets, user1, 0);
        vm.stopPrank();
    }

    function test_RevertWhen_NotSC() public {
        vm.expectRevert(CoreErrors.UnauthorizedCaller.selector);
        stakingModule.slash(0);
    }

    function test_RevertWhen_AmountExceedsMaxSlashable() public {
        // totalStaked is 0
        vm.expectRevert(Errors.MaxSlashableExceeded.selector);
        vm.prank(securityCouncil);
        stakingModule.slash(1);

        // User1 stakes machine shares
        uint256 sharesToStake = DEFAULT_MIN_BALANCE_AFTER_SLASH - 1;
        vm.startPrank(user1);
        machineShare.approve(address(stakingModule), sharesToStake);
        stakingModule.stake(sharesToStake, user3, 0);
        vm.stopPrank();

        // totalStaked < minBalanceAfterSlash
        vm.expectRevert(Errors.MaxSlashableExceeded.selector);
        vm.prank(securityCouncil);
        stakingModule.slash(1);

        // User1 stakes machine shares
        sharesToStake = 1;
        vm.startPrank(user1);
        machineShare.approve(address(stakingModule), sharesToStake);
        stakingModule.stake(sharesToStake, user3, 0);
        vm.stopPrank();

        // totalStaked = minBalanceAfterSlash
        vm.expectRevert(Errors.MaxSlashableExceeded.selector);
        vm.prank(securityCouncil);
        stakingModule.slash(1);

        // User1 stakes machine shares
        sharesToStake = 1;
        vm.startPrank(user1);
        machineShare.approve(address(stakingModule), sharesToStake);
        stakingModule.stake(sharesToStake, user3, 0);
        vm.stopPrank();

        // slash amount makes vault balance fall below minBalanceAfterSlash
        vm.expectRevert(Errors.MaxSlashableExceeded.selector);
        vm.prank(securityCouncil);
        stakingModule.slash(2);

        // User1 stakes machine shares
        sharesToStake = machineShare.balanceOf(user1);
        vm.startPrank(user1);
        machineShare.approve(address(stakingModule), sharesToStake);
        stakingModule.stake(sharesToStake, user3, 0);
        vm.stopPrank();

        // slash amount exceeds max allowed percentage
        uint256 slashAmount = (stakingModule.totalStakedAmount() * DEFAULT_MAX_SLASHABLE_BPS / 10_000) + 1;
        vm.expectRevert(Errors.MaxSlashableExceeded.selector);
        vm.prank(securityCouncil);
        stakingModule.slash(slashAmount);

        // slash amount = max allowed percentage
        // should not revert
        slashAmount = (stakingModule.totalStakedAmount() * DEFAULT_MAX_SLASHABLE_BPS / 10_000);
        vm.prank(securityCouncil);
        stakingModule.slash(slashAmount);
    }

    function test_Slash() public {
        // User1 stakes machine shares
        uint256 sharesToStake = machineShares;
        vm.startPrank(user1);
        machineShare.approve(address(stakingModule), sharesToStake);
        stakingModule.stake(sharesToStake, user3, 0);
        vm.stopPrank();

        uint256 slashAmount = machineShares / 3;

        uint256 rateBefore = stakingModule.convertToAssets(1e18);

        vm.expectEmit(false, false, false, true, address(stakingModule));
        emit IStakingModule.Slash(slashAmount);
        vm.prank(securityCouncil);
        stakingModule.slash(slashAmount);

        assertEq(stakingModule.totalStakedAmount(), machineShares - slashAmount);
        assertEq(machineShare.totalSupply(), machineShares - slashAmount);
        assertTrue(stakingModule.slashingMode());
        assertLt(stakingModule.convertToAssets(1e18), rateBefore);
    }
}
