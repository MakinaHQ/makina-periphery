// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";

import {MockMachinePeriphery} from "test/mocks/MockMachinePeriphery.sol";

import {Integration_Concrete_Test} from "../IntegrationConcrete.t.sol";

abstract contract HubPeripheryFactory_Integration_Concrete_Test is Integration_Concrete_Test {
    function setUp() public virtual override {
        Integration_Concrete_Test.setUp();

        // Deploy and set up dummy machine manager implementation
        address mockMachinePeripheryImplem = address(new MockMachinePeriphery());
        address mockMachinePeripheryBeacon = address(new UpgradeableBeacon(mockMachinePeripheryImplem, dao));
        vm.startPrank(dao);
        hubPeripheryRegistry.setDepositorBeacon(DUMMY_MANAGER_IMPLEM_ID, mockMachinePeripheryBeacon);
        hubPeripheryRegistry.setRedeemerBeacon(DUMMY_MANAGER_IMPLEM_ID, mockMachinePeripheryBeacon);
        hubPeripheryRegistry.setFeeManagerBeacon(DUMMY_MANAGER_IMPLEM_ID, mockMachinePeripheryBeacon);
        vm.stopPrank();
    }
}
