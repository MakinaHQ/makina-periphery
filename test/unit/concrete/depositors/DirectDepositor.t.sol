// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {Machine} from "@makina-core/machine/Machine.sol";

import {IMachinePeriphery} from "src/interfaces/IMachinePeriphery.sol";
import {ISanctionsList} from "src/interfaces/ISanctionsList.sol";
import {IWhitelist} from "src/interfaces/IWhitelist.sol";
import {DirectDepositor} from "src/depositors/DirectDepositor.sol";

import {
    MachinePeriphery_Unit_Concrete_Test,
    Getters_Setters_MachinePeriphery_Unit_Concrete_Test
} from "../machine-periphery/MachinePeriphery.t.sol";
import {SanctionsList_Unit_Concrete_Test} from "../sanctions-list/SanctionsList.t.sol";
import {Whitelist_Unit_Concrete_Test} from "../whitelist/Whitelist.t.sol";
import {Unit_Concrete_Test} from "../UnitConcrete.t.sol";

abstract contract DirectDepositor_Unit_Concrete_Test is MachinePeriphery_Unit_Concrete_Test {
    DirectDepositor internal directDepositor;
    Machine internal machine;

    function setUp() public virtual override {
        Unit_Concrete_Test.setUp();

        vm.prank(dao);
        directDepositor = DirectDepositor(
            hubPeripheryFactory.createDepositor(
                DIRECT_DEPOSITOR_IMPLEM_ID,
                abi.encode(DEFAULT_INITIAL_WHITELIST_STATUS, DEFAULT_INITIAL_SANCTIONS_CHECK_STATUS)
            )
        );

        machinePeriphery = IMachinePeriphery(address(directDepositor));

        (machine,) = _deployMachine(address(accountingToken), address(directDepositor), address(0), address(0));
    }
}

contract Whitelist_DirectDepositor_Unit_Concrete_Test is
    Whitelist_Unit_Concrete_Test,
    DirectDepositor_Unit_Concrete_Test
{
    function setUp() public override(Whitelist_Unit_Concrete_Test, DirectDepositor_Unit_Concrete_Test) {
        DirectDepositor_Unit_Concrete_Test.setUp();
        whitelist = IWhitelist(address(directDepositor));

        vm.prank(dao);
        hubPeripheryFactory.setMachine(address(directDepositor), address(machine));
    }
}

contract SanctionsList_DirectDepositor_Unit_Concrete_Test is
    SanctionsList_Unit_Concrete_Test,
    DirectDepositor_Unit_Concrete_Test
{
    function setUp() public override(SanctionsList_Unit_Concrete_Test, DirectDepositor_Unit_Concrete_Test) {
        DirectDepositor_Unit_Concrete_Test.setUp();
        sanctionsList = ISanctionsList(address(directDepositor));

        vm.prank(dao);
        hubPeripheryFactory.setMachine(address(directDepositor), address(machine));
    }
}

contract Getters_Setters_DirectDepositor_Unit_Concrete_Test is
    Getters_Setters_MachinePeriphery_Unit_Concrete_Test,
    DirectDepositor_Unit_Concrete_Test
{
    function setUp() public override(DirectDepositor_Unit_Concrete_Test, MachinePeriphery_Unit_Concrete_Test) {
        DirectDepositor_Unit_Concrete_Test.setUp();
    }
}
