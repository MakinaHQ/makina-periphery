// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";

import {MockMachineManager} from "test/mocks/MockMachineManager.sol";

import {Integration_Concrete_Test} from "../IntegrationConcrete.t.sol";

abstract contract HubPeripheryFactory_Integration_Concrete_Test is Integration_Concrete_Test {
    function setUp() public virtual override {
        Integration_Concrete_Test.setUp();

        // Deploy and set up dummy machine manager implementation
        address mockMachineManagerImplem = address(new MockMachineManager());
        address mockMachineManagerBeacon = address(new UpgradeableBeacon(mockMachineManagerImplem, dao));
        vm.startPrank(dao);
        hubPeripheryRegistry.setDepositManagerBeacon(DUMMY_MANAGER_IMPLEM_ID, mockMachineManagerBeacon);
        hubPeripheryRegistry.setRedeemManagerBeacon(DUMMY_MANAGER_IMPLEM_ID, mockMachineManagerBeacon);
        hubPeripheryRegistry.setFeeManagerBeacon(DUMMY_MANAGER_IMPLEM_ID, mockMachineManagerBeacon);
        vm.stopPrank();
    }
}
