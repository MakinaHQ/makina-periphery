// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Errors} from "src/libraries/Errors.sol";

import {Unit_Concrete_Test} from "../UnitConcrete.t.sol";

contract Getters_HubPeripheryFactory_Unit_Concrete_Test is Unit_Concrete_Test {
    function test_Getters() public view {
        assertEq(hubPeripheryFactory.peripheryRegistry(), address(hubPeripheryRegistry));
        assertFalse(hubPeripheryFactory.isMachineDepositor(address(0)));
        assertFalse(hubPeripheryFactory.isMachineRedeemer(address(0)));
        assertFalse(hubPeripheryFactory.isFeeManager(address(0)));
    }

    function test_MachineDepositorImplemId_RevertWhen_NotMachineDepositor() public {
        vm.expectRevert(Errors.NotMachineDepositor.selector);
        hubPeripheryFactory.machineDepositorImplemId(address(0));
    }

    function test_MachineRedeemerImplemId_RevertWhen_NotMachineRedeemer() public {
        vm.expectRevert(Errors.NotMachineRedeemer.selector);
        hubPeripheryFactory.machineRedeemerImplemId(address(0));
    }

    function test_FeeManagerImplemId_RevertWhen_NotFeeManager() public {
        vm.expectRevert(Errors.NotFeeManager.selector);
        hubPeripheryFactory.feeManagerImplemId(address(0));
    }
}
