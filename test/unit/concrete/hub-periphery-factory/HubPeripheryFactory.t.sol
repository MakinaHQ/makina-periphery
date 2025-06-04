// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Errors} from "src/libraries/Errors.sol";

import {Unit_Concrete_Test} from "../UnitConcrete.t.sol";

contract Getters_HubPeripheryFactory_Unit_Concrete_Test is Unit_Concrete_Test {
    function test_Getters() public view {
        assertEq(hubPeripheryFactory.peripheryRegistry(), address(hubPeripheryRegistry));
        assertFalse(hubPeripheryFactory.isDepositManager(address(0)));
        assertFalse(hubPeripheryFactory.isRedeemManager(address(0)));
        assertFalse(hubPeripheryFactory.isFeeManager(address(0)));
    }

    function test_DepositManagerImplemId_RevertWhen_NotDepositManager() public {
        vm.expectRevert(Errors.NotDepositManager.selector);
        hubPeripheryFactory.depositManagerImplemId(address(0));
    }

    function test_RedeemManagerImplemId_RevertWhen_NotRedeemManager() public {
        vm.expectRevert(Errors.NotRedeemManager.selector);
        hubPeripheryFactory.redeemManagerImplemId(address(0));
    }

    function test_FeeManagerImplemId_RevertWhen_NotFeeManager() public {
        vm.expectRevert(Errors.NotFeeManager.selector);
        hubPeripheryFactory.feeManagerImplemId(address(0));
    }
}
