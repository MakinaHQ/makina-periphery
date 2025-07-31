// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {IMachine} from "@makina-core/interfaces/IMachine.sol";

import {CoreErrors} from "src/libraries/Errors.sol";

import {WhitelistMachineDepositor_Integration_Concrete_Test} from "../WhitelistMachineDepositor.t.sol";

contract Deposit_Integration_Concrete_Test is WhitelistMachineDepositor_Integration_Concrete_Test {
    function test_RevertWhenUserNotWhitelisted() public {
        vm.expectRevert(CoreErrors.UnauthorizedCaller.selector);
        whitelistMachineDepositor.deposit(0, address(0), 0);
    }

    function test_Deposit() public withMachine(address(machine)) withWhitelistedUser(address(this)) {
        uint256 inputAmount = 1e18;
        uint256 expectedShares = machine.convertToShares(inputAmount);

        deal(address(accountingToken), address(this), inputAmount, true);

        accountingToken.approve(address(whitelistMachineDepositor), inputAmount);

        vm.expectEmit(true, true, false, true, address(machine));
        emit IMachine.Deposit(address(whitelistMachineDepositor), address(this), inputAmount, expectedShares);
        whitelistMachineDepositor.deposit(inputAmount, address(this), expectedShares);

        assertEq(accountingToken.balanceOf(address(this)), 0);
        assertEq(accountingToken.balanceOf(address(whitelistMachineDepositor)), 0);
        assertEq(accountingToken.balanceOf(address(machine)), inputAmount);
        assertEq(machineShare.balanceOf(address(this)), expectedShares);
        assertEq(machine.lastTotalAum(), inputAmount);
    }
}
