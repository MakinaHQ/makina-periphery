// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {IAccessManaged} from "@openzeppelin/contracts/access/manager/IAccessManaged.sol";

import {IHubPeripheryRegistry} from "src/interfaces/IHubPeripheryRegistry.sol";

import {Unit_Concrete_Test} from "../UnitConcrete.t.sol";

contract Getters_Setters_HubPeripheryRegistry_Unit_Concrete_Test is Unit_Concrete_Test {
    function test_Getters() public view {
        assertEq(hubPeripheryRegistry.peripheryFactory(), address(hubPeripheryFactory));
        assertEq(hubPeripheryRegistry.depositorBeacon(DIRECT_DEPOSITOR_IMPLEM_ID), address(directDepositorBeacon));
        assertEq(hubPeripheryRegistry.redeemerBeacon(ASYNC_REDEEMER_IMPLEM_ID), address(asyncRedeemerBeacon));
        assertEq(
            hubPeripheryRegistry.feeManagerBeacon(WATERMARK_FEE_MANAGER_IMPLEM_ID), address(watermarkFeeManagerBeacon)
        );
        assertEq(hubPeripheryRegistry.securityModuleBeacon(), address(securityModuleBeacon));
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

    function test_SetDepositorBeacon_RevertWhen_CallerWithoutRole() public {
        vm.expectRevert(abi.encodeWithSelector(IAccessManaged.AccessManagedUnauthorized.selector, address(this)));
        hubPeripheryRegistry.setDepositorBeacon(DIRECT_DEPOSITOR_IMPLEM_ID, address(0));
    }

    function test_SetDepositorBeacon() public {
        address newDepositorBeacon = makeAddr("newDepositorBeacon");
        vm.expectEmit(true, true, false, false, address(hubPeripheryRegistry));
        emit IHubPeripheryRegistry.DepositorBeaconChanged(
            DIRECT_DEPOSITOR_IMPLEM_ID, address(directDepositorBeacon), newDepositorBeacon
        );
        vm.prank(dao);
        hubPeripheryRegistry.setDepositorBeacon(DIRECT_DEPOSITOR_IMPLEM_ID, newDepositorBeacon);
        assertEq(hubPeripheryRegistry.depositorBeacon(DIRECT_DEPOSITOR_IMPLEM_ID), newDepositorBeacon);
    }

    function test_SetRedeemerBeacon_RevertWhen_CallerWithoutRole() public {
        vm.expectRevert(abi.encodeWithSelector(IAccessManaged.AccessManagedUnauthorized.selector, address(this)));
        hubPeripheryRegistry.setRedeemerBeacon(ASYNC_REDEEMER_IMPLEM_ID, address(0));
    }

    function test_SetRedeemerBeacon() public {
        address newRedeemerBeacon = makeAddr("newRedeemerBeacon");
        vm.expectEmit(true, true, false, false, address(hubPeripheryRegistry));
        emit IHubPeripheryRegistry.RedeemerBeaconChanged(
            ASYNC_REDEEMER_IMPLEM_ID, address(asyncRedeemerBeacon), newRedeemerBeacon
        );
        vm.prank(dao);
        hubPeripheryRegistry.setRedeemerBeacon(ASYNC_REDEEMER_IMPLEM_ID, newRedeemerBeacon);
        assertEq(hubPeripheryRegistry.redeemerBeacon(ASYNC_REDEEMER_IMPLEM_ID), newRedeemerBeacon);
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
