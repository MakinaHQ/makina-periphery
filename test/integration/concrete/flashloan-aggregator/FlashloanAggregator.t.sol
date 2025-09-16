// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {FlashLoanHelpers} from "../../../utils/FlashLoanHelpers.sol";

import {Integration_Concrete_Test} from "../IntegrationConcrete.t.sol";

contract FlashloanAggregator_Integration_Concrete_Test is Integration_Concrete_Test {
    address public caliberAddr;

    function setUp() public virtual override {
        Integration_Concrete_Test.setUp();

        caliberAddr = makeAddr("Caliber");

        FlashLoanHelpers.registerCaliber(address(hubCoreFactory), caliberAddr);
    }
}
