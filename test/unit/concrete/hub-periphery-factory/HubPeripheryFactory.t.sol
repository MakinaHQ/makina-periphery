// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {Errors} from "src/libraries/Errors.sol";

import {Unit_Concrete_Test} from "../UnitConcrete.t.sol";

contract Getters_HubPeripheryFactory_Unit_Concrete_Test is Unit_Concrete_Test {
    function test_Getters() public view {
        assertEq(hubPeripheryFactory.peripheryRegistry(), address(hubPeripheryRegistry));
        assertFalse(hubPeripheryFactory.isDepositor(address(0)));
        assertFalse(hubPeripheryFactory.isRedeemer(address(0)));
        assertFalse(hubPeripheryFactory.isFeeManager(address(0)));
    }

    function test_DepositorImplemId_RevertWhen_NotDepositor() public {
        vm.expectRevert(Errors.NotDepositor.selector);
        hubPeripheryFactory.depositorImplemId(address(0));
    }

    function test_RedeemerImplemId_RevertWhen_NotRedeemer() public {
        vm.expectRevert(Errors.NotRedeemer.selector);
        hubPeripheryFactory.redeemerImplemId(address(0));
    }

    function test_FeeManagerImplemId_RevertWhen_NotFeeManager() public {
        vm.expectRevert(Errors.NotFeeManager.selector);
        hubPeripheryFactory.feeManagerImplemId(address(0));
    }
}
