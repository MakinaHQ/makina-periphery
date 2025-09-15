// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {Machine} from "@makina-core/machine/Machine.sol";

import {IMachinePeriphery} from "src/interfaces/IMachinePeriphery.sol";
import {IWhitelist} from "src/interfaces/IWhitelist.sol";
import {DirectDepositor} from "src/depositors/DirectDepositor.sol";

import {
    MachinePeriphery_Util_Concrete_Test,
    Getter_Setter_MachinePeriphery_Util_Concrete_Test
} from "../machine-periphery/MachinePeriphery.t.sol";
import {Whitelist_Unit_Concrete_Test} from "../whitelist/Whitelist.t.sol";
import {Unit_Concrete_Test} from "../UnitConcrete.t.sol";

abstract contract DirectDepositor_Util_Concrete_Test is MachinePeriphery_Util_Concrete_Test {
    DirectDepositor public directDepositor;

    function setUp() public virtual override {
        Unit_Concrete_Test.setUp();

        vm.prank(dao);
        directDepositor = DirectDepositor(
            hubPeripheryFactory.createDepositor(
                DIRECT_DEPOSITOR_IMPLEM_ID, abi.encode(DEFAULT_INITIAL_WHITELIST_STATUS)
            )
        );

        machinePeriphery = IMachinePeriphery(address(directDepositor));

        (Machine machine,) = _deployMachine(address(accountingToken), address(directDepositor), address(0), address(0));
        _machineAddr = address(machine);
    }
}

contract Whitelist_DirectDepositor_Util_Concrete_Test is
    Whitelist_Unit_Concrete_Test,
    DirectDepositor_Util_Concrete_Test
{
    function setUp() public override(Whitelist_Unit_Concrete_Test, DirectDepositor_Util_Concrete_Test) {
        DirectDepositor_Util_Concrete_Test.setUp();
        whitelist = IWhitelist(address(directDepositor));

        vm.prank(dao);
        hubPeripheryFactory.setMachine(address(directDepositor), _machineAddr);
    }
}

contract Getters_Setters_DirectDepositor_Util_Concrete_Test is
    Getter_Setter_MachinePeriphery_Util_Concrete_Test,
    DirectDepositor_Util_Concrete_Test
{
    function setUp() public override(DirectDepositor_Util_Concrete_Test, MachinePeriphery_Util_Concrete_Test) {
        DirectDepositor_Util_Concrete_Test.setUp();
    }
}
