// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {MockERC20} from "@makina-core-test/mocks/MockERC20.sol";
import {MockPriceFeed} from "@makina-core-test/mocks/MockPriceFeed.sol";

import {Base_Hub_Test} from "test/base/Base.t.sol";

abstract contract Unit_Concrete_Test is Base_Hub_Test {
    MockERC20 public accountingToken;
    MockERC20 public baseToken;

    MockPriceFeed internal aPriceFeed1;
    MockPriceFeed internal bPriceFeed1;

    function setUp() public virtual override {
        Base_Hub_Test.setUp();

        accountingToken = new MockERC20("accountingToken", "ACT", 18);
        baseToken = new MockERC20("baseToken", "BT", 18);

        aPriceFeed1 = new MockPriceFeed(18, 1e18, block.timestamp);
        bPriceFeed1 = new MockPriceFeed(18, 1e18, block.timestamp);

        vm.startPrank(dao);
        oracleRegistry.setFeedRoute(
            address(accountingToken), address(aPriceFeed1), DEFAULT_PF_STALE_THRSHLD, address(0), 0
        );
        oracleRegistry.setFeedRoute(address(baseToken), address(bPriceFeed1), DEFAULT_PF_STALE_THRSHLD, address(0), 0);
        vm.stopPrank();
    }
}
