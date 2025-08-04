// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {MachineShare} from "@makina-core/machine/MachineShare.sol";

import {OpenMachineDepositor} from "src/depositors/OpenMachineDepositor.sol";

import {MachinePeriphery_Integration_Concrete_Test} from "../../machine-periphery/MachinePeriphery.t.sol";

contract OpenMachineDepositor_Integration_Concrete_Test is MachinePeriphery_Integration_Concrete_Test {
    OpenMachineDepositor public openMachineDepositor;

    function setUp() public override {
        MachinePeriphery_Integration_Concrete_Test.setUp();

        vm.prank(dao);
        openMachineDepositor =
            OpenMachineDepositor(hubPeripheryFactory.createMachineDepositor(OPEN_DEPOSIT_MANAGER_IMPLEM_ID, ""));

        (machine,) = _deployMachine(address(accountingToken), address(openMachineDepositor), address(0), address(0));
        machineShare = MachineShare(machine.shareToken());
    }

    modifier withMachine(address _machine) {
        vm.prank(dao);
        hubPeripheryFactory.setMachine(address(openMachineDepositor), _machine);

        _;
    }
}
