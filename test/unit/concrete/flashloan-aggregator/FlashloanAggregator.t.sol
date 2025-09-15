// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {Unit_Concrete_Test} from "../UnitConcrete.t.sol";

abstract contract FlashloanAggregator_Unit_Concrete_Test is Unit_Concrete_Test {
    function setUp() public virtual override {
        Unit_Concrete_Test.setUp();
    }
}

contract Getters_Setters_FlashloanAggregator_Unit_Concrete_Test is FlashloanAggregator_Unit_Concrete_Test {
    function test_Getters() public view {
        assertEq(flashloanAggregator.caliberFactory(), address(hubCoreFactory));
        assertEq(flashloanAggregator.balancerV2Pool(), address(balancerV2Pool));
        assertEq(flashloanAggregator.balancerV3Pool(), address(balancerV3Pool));
        assertEq(flashloanAggregator.morphoPool(), address(morphoPool));
        assertEq(flashloanAggregator.dssFlash(), address(dssFlash));
        assertEq(flashloanAggregator.aaveV3AddressProvider(), address(aaveV3AddressProvider));
        assertEq(flashloanAggregator.dai(), address(dai));
        assertEq(address(flashloanAggregator.ADDRESSES_PROVIDER()), address(aaveV3AddressProvider));
    }
}
