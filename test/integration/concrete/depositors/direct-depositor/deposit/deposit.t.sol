// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {IMachine} from "@makina-core/interfaces/IMachine.sol";

import {Errors, CoreErrors} from "src/libraries/Errors.sol";

import {DirectDepositor_Integration_Concrete_Test} from "../DirectDepositor.t.sol";

contract Deposit_Integration_Concrete_Test is DirectDepositor_Integration_Concrete_Test {
    function test_RevertGiven_MachineNotSet() public {
        vm.expectRevert(Errors.MachineNotSet.selector);
        directDepositor.deposit(0, address(0), 0);
    }

    function test_RevertWhen_UserNotWhitelisted() public withMachine(address(machine)) withWhitelistEnabled {
        vm.expectRevert(CoreErrors.UnauthorizedCaller.selector);
        directDepositor.deposit(0, address(0), 0);
    }

    function test_Deposit() public withMachine(address(machine)) {
        uint256 inputAmount = 1e18;
        uint256 expectedShares = machine.convertToShares(inputAmount);

        deal(address(accountingToken), address(this), inputAmount, true);

        accountingToken.approve(address(directDepositor), inputAmount);

        vm.expectEmit(true, true, false, true, address(machine));
        emit IMachine.Deposit(address(directDepositor), address(this), inputAmount, expectedShares);
        directDepositor.deposit(inputAmount, address(this), expectedShares);

        assertEq(accountingToken.balanceOf(address(this)), 0);
        assertEq(accountingToken.balanceOf(address(directDepositor)), 0);
        assertEq(accountingToken.balanceOf(address(machine)), inputAmount);
        assertEq(machineShare.balanceOf(address(this)), expectedShares);
        assertEq(machine.lastTotalAum(), inputAmount);
    }

    function test_Deposit_WithWhitelistEnabled()
        public
        withMachine(address(machine))
        withWhitelistEnabled
        withWhitelistedUser(address(this))
    {
        uint256 inputAmount = 1e18;
        uint256 expectedShares = machine.convertToShares(inputAmount);

        deal(address(accountingToken), address(this), inputAmount, true);

        accountingToken.approve(address(directDepositor), inputAmount);

        vm.expectEmit(true, true, false, true, address(machine));
        emit IMachine.Deposit(address(directDepositor), address(this), inputAmount, expectedShares);
        directDepositor.deposit(inputAmount, address(this), expectedShares);

        assertEq(accountingToken.balanceOf(address(this)), 0);
        assertEq(accountingToken.balanceOf(address(directDepositor)), 0);
        assertEq(accountingToken.balanceOf(address(machine)), inputAmount);
        assertEq(machineShare.balanceOf(address(this)), expectedShares);
        assertEq(machine.lastTotalAum(), inputAmount);
    }
}
