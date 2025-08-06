// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {IMachine} from "@makina-core/interfaces/IMachine.sol";

import {Errors} from "src/libraries/Errors.sol";

import {OpenMachineDepositor_Integration_Concrete_Test} from "../OpenMachineDepositor.t.sol";

contract Deposit_Integration_Concrete_Test is OpenMachineDepositor_Integration_Concrete_Test {
    function test_RevertGivenMachineNotSet() public {
        vm.expectRevert(Errors.MachineNotSet.selector);
        openMachineDepositor.deposit(0, address(0), 0);
    }

    function test_Deposit() public withMachine(address(machine)) {
        uint256 inputAmount = 1e18;
        uint256 expectedShares = machine.convertToShares(inputAmount);

        deal(address(accountingToken), address(this), inputAmount, true);

        accountingToken.approve(address(openMachineDepositor), inputAmount);

        vm.expectEmit(true, true, false, true, address(machine));
        emit IMachine.Deposit(address(openMachineDepositor), address(this), inputAmount, expectedShares);
        openMachineDepositor.deposit(inputAmount, address(this), expectedShares);

        assertEq(accountingToken.balanceOf(address(this)), 0);
        assertEq(accountingToken.balanceOf(address(openMachineDepositor)), 0);
        assertEq(accountingToken.balanceOf(address(machine)), inputAmount);
        assertEq(machineShare.balanceOf(address(this)), expectedShares);
        assertEq(machine.lastTotalAum(), inputAmount);
    }
}
