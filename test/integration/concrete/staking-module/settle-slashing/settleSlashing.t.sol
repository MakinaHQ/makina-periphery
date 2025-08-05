// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {IStakingModule} from "src/interfaces/IStakingModule.sol";
import {CoreErrors} from "src/libraries/Errors.sol";

import {StakingModule_Integration_Concrete_Test} from "../StakingModule.t.sol";

contract SettleSlashing_Integration_Concrete_Test is StakingModule_Integration_Concrete_Test {
    uint256 private machineShares;

    function setUp() public override {
        StakingModule_Integration_Concrete_Test.setUp();

        // Deposit assets to the machine
        uint256 inputAssets = 3 * DEFAULT_MIN_BALANCE_AFTER_SLASH;
        deal(address(accountingToken), machineDepositorAddr, inputAssets);
        vm.startPrank(machineDepositorAddr);
        accountingToken.approve(address(machine), inputAssets);
        machineShares = machine.deposit(inputAssets, user1, 0);
        vm.stopPrank();
    }

    function test_RevertWhen_NotSC() public {
        vm.expectRevert(CoreErrors.UnauthorizedCaller.selector);
        stakingModule.settleSlashing();
    }

    function test_Slash() public {
        // User1 stakes machine shares
        uint256 sharesToStake = machineShares;
        vm.startPrank(user1);
        machineShare.approve(address(stakingModule), sharesToStake);
        stakingModule.stake(sharesToStake, user3, 0);
        vm.stopPrank();

        vm.prank(securityCouncil);
        stakingModule.slash(machineShares / 3);

        vm.expectEmit(false, false, false, false, address(stakingModule));
        emit IStakingModule.SlashingSettled();
        vm.prank(securityCouncil);
        stakingModule.settleSlashing();

        assertFalse(stakingModule.slashingMode());
    }
}
