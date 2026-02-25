// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {Machine} from "@makina-core/machine/Machine.sol";
import {MachineShare} from "@makina-core/machine/MachineShare.sol";

import {Integration_Concrete_Test} from "../IntegrationConcrete.t.sol";

abstract contract MachinePeriphery_Integration_Concrete_Test is Integration_Concrete_Test {
    Machine internal machine;
    MachineShare internal machineShare;

    address internal user1;
    address internal user2;
    address internal user3;
    address internal user4;

    function setUp() public virtual override {
        Integration_Concrete_Test.setUp();

        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        user3 = makeAddr("user3");
        user4 = makeAddr("user4");
    }
}
