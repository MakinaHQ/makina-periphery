// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {IFlashloanAggregator} from "src/interfaces/IFlashloanAggregator.sol";
import {FlashloanAggregator} from "src/flashloans/FlashloanAggregator.sol";

import {FlashloanAggregator_Integration_Concrete_Test} from "../FlashloanAggregator.t.sol";

contract ExecuteOperation_Integration_Concrete_Test is FlashloanAggregator_Integration_Concrete_Test {
    address private _pool;

    function setUp() public override {
        FlashloanAggregator_Integration_Concrete_Test.setUp();

        _pool = makeAddr("POOL");

        flashloanAggregator = new FlashloanAggregator(
            address(hubCoreFactory), address(0), address(0), address(0), address(0), address(this), address(0)
        );
    }

    function test_RevertWhen_NotAaveV3Pool() public {
        vm.expectRevert(IFlashloanAggregator.NotAaveV3Pool.selector);
        flashloanAggregator.executeOperation(address(0), 0, 0, address(0), "");
    }

    function test_RevertWhen_NotRequested() public {
        vm.expectRevert(IFlashloanAggregator.NotRequested.selector);
        vm.prank(getPool());
        flashloanAggregator.executeOperation(address(0), 0, 0, address(0), "");
    }

    /// @dev Mocks the getPool function of aaveV3AddressProvider.
    function getPool() public view returns (address) {
        return _pool;
    }
}
