// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {IAccessManaged} from "@openzeppelin/contracts/access/manager/IAccessManaged.sol";

import {IHubPeripheryRegistry} from "src/interfaces/IHubPeripheryRegistry.sol";

import {Unit_Concrete_Test} from "../UnitConcrete.t.sol";

contract Getters_Setters_HubPeripheryRegistry_Unit_Concrete_Test is Unit_Concrete_Test {
    function test_Getters() public view {
        assertEq(hubPeripheryRegistry.peripheryFactory(), address(hubPeripheryFactory));
        assertEq(
            hubPeripheryRegistry.machineDepositorBeacon(OPEN_DEPOSIT_MANAGER_IMPLEM_ID),
            address(openMachineDepositorBeacon)
        );
        assertEq(
            hubPeripheryRegistry.machineDepositorBeacon(WHITELISTED_DEPOSIT_MANAGER_IMPLEM_ID),
            address(whitelistMachineDepositorBeacon)
        );

        assertEq(
            hubPeripheryRegistry.machineRedeemerBeacon(ASYNC_REDEEM_MANAGER_IMPLEM_ID),
            address(asyncMachineRedeemerBeacon)
        );
        assertEq(
            hubPeripheryRegistry.machineRedeemerBeacon(WHITELISTED_ASYNC_REDEEM_MANAGER_IMPLEM_ID),
            address(whitelistAsyncMachineRedeemerBeacon)
        );

        assertEq(
            hubPeripheryRegistry.feeManagerBeacon(WATERMARK_FEE_MANAGER_IMPLEM_ID), address(watermarkFeeManagerBeacon)
        );
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
        hubPeripheryRegistry.setMachineDepositorBeacon(OPEN_DEPOSIT_MANAGER_IMPLEM_ID, address(0));
    }

    function test_SetMachineDepositorBeacon() public {
        address newMachineDepositorBeacon = makeAddr("newMachineDepositorBeacon");
        vm.expectEmit(true, true, false, false, address(hubPeripheryRegistry));
        emit IHubPeripheryRegistry.MachineDepositorBeaconChanged(
            OPEN_DEPOSIT_MANAGER_IMPLEM_ID, address(openMachineDepositorBeacon), newMachineDepositorBeacon
        );
        vm.prank(dao);
        hubPeripheryRegistry.setMachineDepositorBeacon(OPEN_DEPOSIT_MANAGER_IMPLEM_ID, newMachineDepositorBeacon);
        assertEq(hubPeripheryRegistry.machineDepositorBeacon(OPEN_DEPOSIT_MANAGER_IMPLEM_ID), newMachineDepositorBeacon);
    }

    function test_SetMachineRedeemerBeacon_RevertWhen_CallerWithoutRole() public {
        vm.expectRevert(abi.encodeWithSelector(IAccessManaged.AccessManagedUnauthorized.selector, address(this)));
        hubPeripheryRegistry.setMachineRedeemerBeacon(ASYNC_REDEEM_MANAGER_IMPLEM_ID, address(0));
    }

    function test_SetMachineRedeemerBeacon() public {
        address newMachineRedeemerBeacon = makeAddr("newMachineRedeemerBeacon");
        vm.expectEmit(true, true, false, false, address(hubPeripheryRegistry));
        emit IHubPeripheryRegistry.MachineRedeemerBeaconChanged(
            ASYNC_REDEEM_MANAGER_IMPLEM_ID, address(asyncMachineRedeemerBeacon), newMachineRedeemerBeacon
        );
        vm.prank(dao);
        hubPeripheryRegistry.setMachineRedeemerBeacon(ASYNC_REDEEM_MANAGER_IMPLEM_ID, newMachineRedeemerBeacon);
        assertEq(hubPeripheryRegistry.machineRedeemerBeacon(ASYNC_REDEEM_MANAGER_IMPLEM_ID), newMachineRedeemerBeacon);
    }

    function test_SetFeeManagerBeacon_RevertWhen_CallerWithoutRole() public {
        vm.expectRevert(abi.encodeWithSelector(IAccessManaged.AccessManagedUnauthorized.selector, address(this)));
        hubPeripheryRegistry.setFeeManagerBeacon(WATERMARK_FEE_MANAGER_IMPLEM_ID, address(0));
    }

    function test_SetFeeManagerBeacon() public {
        address newFeeManagerBeacon = makeAddr("newFeeManagerBeacon");
        vm.expectEmit(true, true, false, false, address(hubPeripheryRegistry));
        emit IHubPeripheryRegistry.FeeManagerBeaconChanged(
            WATERMARK_FEE_MANAGER_IMPLEM_ID, address(watermarkFeeManagerBeacon), newFeeManagerBeacon
        );
        vm.prank(dao);
        hubPeripheryRegistry.setFeeManagerBeacon(WATERMARK_FEE_MANAGER_IMPLEM_ID, newFeeManagerBeacon);
        assertEq(hubPeripheryRegistry.feeManagerBeacon(WATERMARK_FEE_MANAGER_IMPLEM_ID), newFeeManagerBeacon);
    }
}
