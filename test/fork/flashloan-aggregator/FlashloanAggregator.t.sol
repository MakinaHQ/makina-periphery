// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {IPoolAddressesProvider} from "@aave/interfaces/IPoolAddressesProvider.sol";

import {FlashLoanHelpers} from "../../utils/FlashLoanHelpers.sol";
import {MockCaliber} from "../../mocks/MockCaliber.sol";

import {Fork_Test} from "../Fork.t.sol";

abstract contract FlashloanAggregator_Fork_Test is Fork_Test {
    MockCaliber public mockCaliber;

    function setUp() public override {
        Fork_Test.setUp();

        mockCaliber = new MockCaliber();

        FlashLoanHelpers.registerCaliber(address(hubCoreFactory), address(mockCaliber));
        assertTrue(hubCoreFactory.isCaliber(address(mockCaliber)));
    }
}

contract Getters_FlashloanAggregator_Fork_Test is Fork_Test {
    function test_Getters() public view {
        assertEq(
            address(flashloanAggregator.POOL()),
            IPoolAddressesProvider(flashloanAggregator.aaveV3AddressProvider()).getPool()
        );
    }
}
