// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {IAccessManaged} from "@openzeppelin/contracts/access/manager/IAccessManaged.sol";

import {IHubPeripheryFactory} from "src/interfaces/IHubPeripheryFactory.sol";
import {Errors} from "src/libraries/Errors.sol";

import {HubPeripheryFactory_Integration_Concrete_Test} from "../HubPeripheryFactory.t.sol";

contract CreateRedeemer_Integration_Concrete_Test is HubPeripheryFactory_Integration_Concrete_Test {
    function test_RevertWhen_CallerWithoutRole() public {
        vm.expectRevert(abi.encodeWithSelector(IAccessManaged.AccessManagedUnauthorized.selector, address(this)));
        hubPeripheryFactory.createRedeemer(0, "");
    }

    function test_RevertWhen_InvalidImplemId() public {
        uint16 implemId = type(uint16).max;

        vm.prank(dao);
        vm.expectRevert(Errors.InvalidRedeemerImplemId.selector);
        hubPeripheryFactory.createRedeemer(implemId, "");
    }

    function test_CreateRedeemer_DummyManager() public {
        uint16 implemId = DUMMY_MANAGER_IMPLEM_ID;

        vm.expectEmit(false, true, false, false, address(hubPeripheryFactory));
        emit IHubPeripheryFactory.RedeemerCreated(address(0), implemId);
        vm.prank(dao);
        address redeemer = hubPeripheryFactory.createRedeemer(implemId, "");

        assertTrue(hubPeripheryFactory.isRedeemer(redeemer));
        assertEq(hubPeripheryFactory.redeemerImplemId(redeemer), implemId);
    }
}
