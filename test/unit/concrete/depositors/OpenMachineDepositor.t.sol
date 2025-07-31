// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Machine} from "@makina-core/machine/Machine.sol";

import {IMachinePeriphery} from "src/interfaces/IMachinePeriphery.sol";
import {OpenMachineDepositor} from "src/depositors/OpenMachineDepositor.sol";

import {
    MachinePeriphery_Util_Concrete_Test,
    Getter_Setter_MachinePeriphery_Util_Concrete_Test
} from "../machine-periphery/MachinePeriphery.t.sol";
import {Unit_Concrete_Test} from "../UnitConcrete.t.sol";

abstract contract OpenMachineDepositor_Util_Concrete_Test is MachinePeriphery_Util_Concrete_Test {
    OpenMachineDepositor public openMachineDepositor;

    function setUp() public virtual override {
        Unit_Concrete_Test.setUp();

        vm.prank(dao);
        openMachineDepositor =
            OpenMachineDepositor(hubPeripheryFactory.createMachineDepositor(OPEN_DEPOSIT_MANAGER_IMPLEM_ID, ""));

        machinePeriphery = IMachinePeriphery(address(openMachineDepositor));

        (Machine machine,) =
            _deployMachine(address(accountingToken), address(openMachineDepositor), address(0), address(0));
        _machineAddr = address(machine);
    }
}

contract Getters_Setters_MachineDepositor_Util_Concrete_Test is
    Getter_Setter_MachinePeriphery_Util_Concrete_Test,
    OpenMachineDepositor_Util_Concrete_Test
{
    function setUp() public override(OpenMachineDepositor_Util_Concrete_Test, MachinePeriphery_Util_Concrete_Test) {
        OpenMachineDepositor_Util_Concrete_Test.setUp();
        machinePeriphery = IMachinePeriphery(address(openMachineDepositor));
    }
}
