// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {IAccessManaged} from "@openzeppelin/contracts/access/manager/IAccessManaged.sol";

import {IHubPeripheryFactory} from "src/interfaces/IHubPeripheryFactory.sol";
import {Errors} from "src/libraries/Errors.sol";

import {HubPeripheryFactory_Integration_Concrete_Test} from "../HubPeripheryFactory.t.sol";

contract CreateRedeemManager_Integration_Concrete_Test is HubPeripheryFactory_Integration_Concrete_Test {
    function test_RevertWhen_CallerWithoutRole() public {
        vm.expectRevert(abi.encodeWithSelector(IAccessManaged.AccessManagedUnauthorized.selector, address(this)));
        hubPeripheryFactory.createRedeemManager(0, address(0), "");
    }

    function test_RevertWhen_InvalidImplemId() public {
        uint16 implemId = type(uint16).max;

        vm.prank(dao);
        vm.expectRevert(Errors.InvalidRedeemManagerImplemId.selector);
        hubPeripheryFactory.createRedeemManager(implemId, address(0), "");
    }

    function test_CreateRedeemManager_DummyManager() public {
        uint16 implemId = DUMMY_MANAGER_IMPLEM_ID;

        vm.expectEmit(false, true, false, false, address(hubPeripheryFactory));
        emit IHubPeripheryFactory.RedeemManagerCreated(address(0), implemId);
        vm.prank(dao);
        address redeemManager = hubPeripheryFactory.createRedeemManager(implemId, address(0), "");

        assertTrue(hubPeripheryFactory.isRedeemManager(redeemManager));
        assertEq(hubPeripheryFactory.redeemManagerImplemId(redeemManager), implemId);
    }
}
