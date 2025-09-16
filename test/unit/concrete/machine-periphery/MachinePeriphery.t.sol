// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {IMachinePeriphery} from "src/interfaces/IMachinePeriphery.sol";
import {Errors, CoreErrors} from "src/libraries/Errors.sol";

import {Unit_Concrete_Test} from "../UnitConcrete.t.sol";

abstract contract MachinePeriphery_Util_Concrete_Test is Unit_Concrete_Test {
    IMachinePeriphery public machinePeriphery;

    address public _machineAddr;

    function setUp() public virtual override {}
}

abstract contract Getter_Setter_MachinePeriphery_Util_Concrete_Test is MachinePeriphery_Util_Concrete_Test {
    function test_GetMachine_RevertGiven_MachineNotSet() public {
        vm.expectRevert(Errors.MachineNotSet.selector);
        machinePeriphery.machine();
    }

    function test_SetMachine_RevertWhen_CallerWithoutRole() public {
        vm.expectRevert(CoreErrors.NotFactory.selector);
        machinePeriphery.setMachine(address(0));
    }

    function test_SetMachine_RevertGiven_MachineAlreadySet() public {
        address newMachine = makeAddr("newMachine");
        vm.prank(address(hubPeripheryFactory));
        machinePeriphery.setMachine(newMachine);

        vm.prank(address(hubPeripheryFactory));
        vm.expectRevert(Errors.MachineAlreadySet.selector);
        machinePeriphery.setMachine(newMachine);
    }

    function test_SetMachine_RevertWhen_ZeroMachineAddress() public {
        address newMachine = address(0);

        vm.prank(address(hubPeripheryFactory));
        vm.expectRevert(Errors.ZeroMachineAddress.selector);
        machinePeriphery.setMachine(newMachine);
    }

    function test_SetMachine() public {
        address newMachine = makeAddr("newMachine");

        vm.expectEmit(true, false, false, false, address(machinePeriphery));
        emit IMachinePeriphery.MachineSet(newMachine);

        vm.prank(address(hubPeripheryFactory));
        machinePeriphery.setMachine(newMachine);
        assertEq(machinePeriphery.machine(), newMachine);
    }
}
