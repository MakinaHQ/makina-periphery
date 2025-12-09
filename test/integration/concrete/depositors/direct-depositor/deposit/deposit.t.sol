// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {IMachine} from "@makina-core/interfaces/IMachine.sol";

import {Errors, CoreErrors} from "src/libraries/Errors.sol";

import {DirectDepositor_Integration_Concrete_Test} from "../DirectDepositor.t.sol";

contract Deposit_Integration_Concrete_Test is DirectDepositor_Integration_Concrete_Test {
    function test_RevertGiven_MachineNotSet() public {
        vm.expectRevert(Errors.MachineNotSet.selector);
        directDepositor.deposit(0, address(0), 0, 0);
    }

    function test_RevertWhen_UserNotWhitelisted() public withMachine(address(machine)) withWhitelistEnabled {
        vm.expectRevert(CoreErrors.UnauthorizedCaller.selector);
        directDepositor.deposit(0, address(0), 0, 0);
    }

    function test_Deposit() public withMachine(address(machine)) {
        _test_Deposit();
    }

    function test_Deposit_WithReferral() public withMachine(address(machine)) {
        _test_Deposit_WithReferral();
    }

    function test_Deposit_WithWhitelistEnabled()
        public
        withMachine(address(machine))
        withWhitelistEnabled
        withWhitelistedUser(address(this))
    {
        _test_Deposit();
    }

    function test_Deposit_WithWhitelistEnabled_WithReferral()
        public
        withMachine(address(machine))
        withWhitelistEnabled
        withWhitelistedUser(address(this))
    {
        _test_Deposit_WithReferral();
    }

    function _test_Deposit() internal {
        uint256 inputAmount = 1e18;
        uint256 expectedShares = machine.convertToShares(inputAmount);

        deal(address(accountingToken), address(this), inputAmount, true);

        accountingToken.approve(address(directDepositor), inputAmount);

        vm.expectEmit(true, true, true, true, address(machine));
        emit IMachine.Deposit(address(directDepositor), address(this), inputAmount, expectedShares, 0);
        directDepositor.deposit(inputAmount, address(this), expectedShares, 0);

        assertEq(accountingToken.balanceOf(address(this)), 0);
        assertEq(accountingToken.balanceOf(address(directDepositor)), 0);
        assertEq(accountingToken.balanceOf(address(machine)), inputAmount);
        assertEq(machineShare.balanceOf(address(this)), expectedShares);
        assertEq(machine.lastTotalAum(), inputAmount);
    }

    function _test_Deposit_WithReferral() internal {
        uint256 inputAmount = 1e18;
        uint256 expectedShares = machine.convertToShares(inputAmount);
        bytes32 referralKey = keccak256("referrer");

        deal(address(accountingToken), address(this), inputAmount, true);

        accountingToken.approve(address(directDepositor), inputAmount);

        vm.expectEmit(true, true, true, true, address(machine));
        emit IMachine.Deposit(address(directDepositor), address(this), inputAmount, expectedShares, referralKey);
        directDepositor.deposit(inputAmount, address(this), expectedShares, referralKey);

        assertEq(accountingToken.balanceOf(address(this)), 0);
        assertEq(accountingToken.balanceOf(address(directDepositor)), 0);
        assertEq(accountingToken.balanceOf(address(machine)), inputAmount);
        assertEq(machineShare.balanceOf(address(this)), expectedShares);
        assertEq(machine.lastTotalAum(), inputAmount);
    }
}
