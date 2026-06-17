// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";

import {CoreErrors} from "src/libraries/Errors.sol";

import {DirectDepositorPausable_Integration_Concrete_Test} from "../DirectDepositorPausable.t.sol";

contract TogglePause_Integration_Concrete_Test is DirectDepositorPausable_Integration_Concrete_Test {
    function test_RevertWhen_CallerNotRiskManager() public withMachine(address(machine)) {
        vm.expectRevert(CoreErrors.UnauthorizedCaller.selector);
        vm.prank(mechanic);
        directDepositor.togglePause();
    }

    function test_TogglePause_Pause() public withMachine(address(machine)) {
        assertFalse(directDepositor.paused());

        vm.expectEmit(true, true, true, true, address(directDepositor));
        emit Pausable.Paused(riskManager);
        vm.prank(riskManager);
        directDepositor.togglePause();

        assertTrue(directDepositor.paused());
    }

    function test_TogglePause_Unpause() public withMachine(address(machine)) withPaused {
        assertTrue(directDepositor.paused());

        vm.expectEmit(true, true, true, true, address(directDepositor));
        emit Pausable.Unpaused(riskManager);
        vm.prank(riskManager);
        directDepositor.togglePause();

        assertFalse(directDepositor.paused());
    }
}
