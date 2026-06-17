// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";

import {IMachine} from "@makina-core/interfaces/IMachine.sol";

import {DirectDepositorPausable_Integration_Concrete_Test} from "../DirectDepositorPausable.t.sol";

contract Deposit_DirectDepositorPausable_Integration_Concrete_Test is
    DirectDepositorPausable_Integration_Concrete_Test
{
    function test_RevertWhen_Paused() public withMachine(address(machine)) withPaused {
        vm.expectRevert(Pausable.EnforcedPause.selector);
        directDepositor.deposit(0, address(this), 0, 0);
    }

    /// @dev An otherwise-valid deposit (funded and approved) must still revert while paused,
    ///      and leave all balances untouched.
    function test_RevertWhen_Paused_WithValidParams() public withMachine(address(machine)) withPaused {
        uint256 inputAmount = 1e18;
        uint256 expectedShares = machine.convertToShares(inputAmount);

        deal(address(accountingToken), address(this), inputAmount, true);
        accountingToken.approve(address(directDepositor), inputAmount);

        vm.expectRevert(Pausable.EnforcedPause.selector);
        directDepositor.deposit(inputAmount, address(this), expectedShares, 0);

        // No assets moved and no shares minted.
        assertEq(accountingToken.balanceOf(address(this)), inputAmount);
        assertEq(accountingToken.balanceOf(address(directDepositor)), 0);
        assertEq(accountingToken.balanceOf(address(machine)), 0);
        assertEq(machineShare.balanceOf(address(this)), 0);
    }

    /// @dev The pause check takes precedence even for a whitelisted user when the whitelist is enabled.
    function test_RevertWhen_Paused_WithWhitelistedUser()
        public
        withMachine(address(machine))
        withWhitelistEnabled
        withWhitelistedUser(address(this))
        withPaused
    {
        uint256 inputAmount = 1e18;

        deal(address(accountingToken), address(this), inputAmount, true);
        accountingToken.approve(address(directDepositor), inputAmount);

        vm.expectRevert(Pausable.EnforcedPause.selector);
        directDepositor.deposit(inputAmount, address(this), 0, 0);
    }

    function test_Deposit_WhenNotPaused() public withMachine(address(machine)) {
        _test_Deposit();
    }

    function test_Deposit_AfterUnpause() public withMachine(address(machine)) withPaused {
        // Deposits are blocked while paused.
        vm.expectRevert(Pausable.EnforcedPause.selector);
        directDepositor.deposit(0, address(this), 0, 0);

        // Unpause and confirm deposits resume.
        vm.prank(riskManager);
        directDepositor.togglePause();

        _test_Deposit();
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
}
