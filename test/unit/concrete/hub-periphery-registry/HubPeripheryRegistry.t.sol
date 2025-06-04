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
        assertEq(hubPeripheryRegistry.depositManagerBeacon(implemId), address(0));
        assertEq(hubPeripheryRegistry.redeemManagerBeacon(implemId), address(0));
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

    function test_SetDepositManagerBeacon_RevertWhen_CallerWithoutRole() public {
        vm.expectRevert(abi.encodeWithSelector(IAccessManaged.AccessManagedUnauthorized.selector, address(this)));
        hubPeripheryRegistry.setDepositManagerBeacon(implemId, address(0));
    }

    function test_SetDepositManagerBeacon() public {
        address newDepositManagerBeacon = makeAddr("newDepositManagerBeacon");
        vm.expectEmit(true, true, false, false, address(hubPeripheryRegistry));
        emit IHubPeripheryRegistry.DepositManagerBeaconChanged(implemId, address(0), newDepositManagerBeacon);
        vm.prank(dao);
        hubPeripheryRegistry.setDepositManagerBeacon(implemId, newDepositManagerBeacon);
        assertEq(hubPeripheryRegistry.depositManagerBeacon(implemId), newDepositManagerBeacon);
    }

    function test_SetRedeemManagerBeacon_RevertWhen_CallerWithoutRole() public {
        vm.expectRevert(abi.encodeWithSelector(IAccessManaged.AccessManagedUnauthorized.selector, address(this)));
        hubPeripheryRegistry.setRedeemManagerBeacon(implemId, address(0));
    }

    function test_SetRedeemManagerBeacon() public {
        address newRedeemManagerBeacon = makeAddr("newRedeemManagerBeacon");
        vm.expectEmit(true, true, false, false, address(hubPeripheryRegistry));
        emit IHubPeripheryRegistry.RedeemManagerBeaconChanged(implemId, address(0), newRedeemManagerBeacon);
        vm.prank(dao);
        hubPeripheryRegistry.setRedeemManagerBeacon(implemId, newRedeemManagerBeacon);
        assertEq(hubPeripheryRegistry.redeemManagerBeacon(implemId), newRedeemManagerBeacon);
    }

    function test_SetFeeanagerBeacon_RevertWhen_CallerWithoutRole() public {
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
