// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {IFlashloanAggregator} from "src/interfaces/IFlashloanAggregator.sol";

import {FlashloanAggregator_Integration_Concrete_Test} from "../FlashloanAggregator.t.sol";

contract OnFlashloan_Integration_Concrete_Test is FlashloanAggregator_Integration_Concrete_Test {
    function test_RevertWhen_NotDssFlash() public {
        vm.expectRevert(IFlashloanAggregator.NotDssFlash.selector);
        flashloanAggregator.onFlashLoan(address(0), address(0), 0, 0, "");
    }

    function test_RevertWhen_NotRequested() public {
        vm.expectRevert(IFlashloanAggregator.NotRequested.selector);
        vm.prank(dssFlash);
        flashloanAggregator.onFlashLoan(address(0), address(0), 0, 0, "");
    }

    function test_RevertWhen_InvalidFeeAmount() public {
        vm.expectRevert(IFlashloanAggregator.InvalidFeeAmount.selector);
        vm.prank(dssFlash);
        flashloanAggregator.onFlashLoan(address(flashloanAggregator), address(0), 0, 1, "");
    }
}
