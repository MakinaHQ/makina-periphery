// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {IAccessManaged} from "@openzeppelin/contracts/access/manager/IAccessManaged.sol";

import {IHubPeripheryRegistry} from "src/interfaces/IHubPeripheryRegistry.sol";

import {Unit_Concrete_Test} from "../UnitConcrete.t.sol";

contract Getters_Setters_HubPeripheryRegistry_Unit_Concrete_Test is Unit_Concrete_Test {
    uint16 private implemId;

    function setUp() public override {
        Unit_Concrete_Test.setUp();

        implemId = 1;
    }

    function test_Getters() public view {
        assertEq(hubPeripheryRegistry.peripheryFactory(), address(hubPeripheryFactory));
        assertEq(hubPeripheryRegistry.machineDepositorBeacon(implemId), address(0));
        assertEq(hubPeripheryRegistry.machineRedeemerBeacon(implemId), address(0));
    }

    function test_SetPeripheryFactory_RevertWhen_CallerWithoutRole() public {
        vm.expectRevert(abi.encodeWithSelector(IAccessManaged.AccessManagedUnauthorized.selector, address(this)));
        hubPeripheryRegistry.setPeripheryFactory(address(0));
    }

    function test_SetPeripheryFactory() public {
        address newPeripheryFactory = makeAddr("newPeripheryFactory");
        vm.expectEmit(true, true, false, false, address(hubPeripheryRegistry));
        emit IHubPeripheryRegistry.PeripheryFactoryChanged(address(hubPeripheryFactory), newPeripheryFactory);
        vm.prank(dao);
        hubPeripheryRegistry.setPeripheryFactory(newPeripheryFactory);
        assertEq(hubPeripheryRegistry.peripheryFactory(), newPeripheryFactory);
    }

    function test_SetMachineDepositorBeacon_RevertWhen_CallerWithoutRole() public {
        vm.expectRevert(abi.encodeWithSelector(IAccessManaged.AccessManagedUnauthorized.selector, address(this)));
        hubPeripheryRegistry.setMachineDepositorBeacon(implemId, address(0));
    }

    function test_SetMachineDepositorBeacon() public {
        address newMachineDepositorBeacon = makeAddr("newMachineDepositorBeacon");
        vm.expectEmit(true, true, false, false, address(hubPeripheryRegistry));
        emit IHubPeripheryRegistry.MachineDepositorBeaconChanged(implemId, address(0), newMachineDepositorBeacon);
        vm.prank(dao);
        hubPeripheryRegistry.setMachineDepositorBeacon(implemId, newMachineDepositorBeacon);
        assertEq(hubPeripheryRegistry.machineDepositorBeacon(implemId), newMachineDepositorBeacon);
    }

    function test_SetMachineRedeemerBeacon_RevertWhen_CallerWithoutRole() public {
        vm.expectRevert(abi.encodeWithSelector(IAccessManaged.AccessManagedUnauthorized.selector, address(this)));
        hubPeripheryRegistry.setMachineRedeemerBeacon(implemId, address(0));
    }

    function test_SetMachineRedeemerBeacon() public {
        address newMachineRedeemerBeacon = makeAddr("newMachineRedeemerBeacon");
        vm.expectEmit(true, true, false, false, address(hubPeripheryRegistry));
        emit IHubPeripheryRegistry.MachineRedeemerBeaconChanged(
            implemId, address(0), newMachineRedeemerBeacon
        );
        vm.prank(dao);
        hubPeripheryRegistry.setMachineRedeemerBeacon(implemId, newMachineRedeemerBeacon);
        assertEq(hubPeripheryRegistry.machineRedeemerBeacon(implemId), newMachineRedeemerBeacon);
    }

    function test_SetFeeManagerBeacon_RevertWhen_CallerWithoutRole() public {
        vm.expectRevert(abi.encodeWithSelector(IAccessManaged.AccessManagedUnauthorized.selector, address(this)));
        hubPeripheryRegistry.setFeeManagerBeacon(implemId, address(0));
    }

    function test_SetFeeManagerBeacon() public {
        address newFeeManagerBeacon = makeAddr("newFeeManagerBeacon");
        vm.expectEmit(true, true, false, false, address(hubPeripheryRegistry));
        emit IHubPeripheryRegistry.FeeManagerBeaconChanged(implemId, address(0), newFeeManagerBeacon);
        vm.prank(dao);
        hubPeripheryRegistry.setFeeManagerBeacon(implemId, newFeeManagerBeacon);
        assertEq(hubPeripheryRegistry.feeManagerBeacon(implemId), newFeeManagerBeacon);
    }
}
