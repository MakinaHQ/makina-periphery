// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Machine} from "@makina-core/machine/Machine.sol";

import {Errors} from "src/libraries/Errors.sol";
import {IMachinePeriphery} from "src/interfaces/IMachinePeriphery.sol";
import {IWhitelist} from "src/interfaces/IWhitelist.sol";
import {WhitelistMachineDepositor} from "src/depositors/WhitelistMachineDepositor.sol";

import {
    MachinePeriphery_Util_Concrete_Test,
    Getter_Setter_MachinePeriphery_Util_Concrete_Test
} from "../machine-periphery/MachinePeriphery.t.sol";
import {Whitelist_Unit_Concrete_Test} from "../whitelist/Whitelist.t.sol";
import {Unit_Concrete_Test} from "../UnitConcrete.t.sol";

abstract contract WhitelistMachineDepositor_Util_Concrete_Test is MachinePeriphery_Util_Concrete_Test {
    WhitelistMachineDepositor public whitelistMachineDepositor;

    function setUp() public virtual override {
        Unit_Concrete_Test.setUp();

        vm.prank(dao);
        whitelistMachineDepositor = WhitelistMachineDepositor(
            hubPeripheryFactory.createMachineDepositor(WHITELISTED_DEPOSIT_MANAGER_IMPLEM_ID, "")
        );

        machinePeriphery = IMachinePeriphery(address(whitelistMachineDepositor));

        (Machine machine,) =
            _deployMachine(address(accountingToken), address(whitelistMachineDepositor), address(0), address(0));
        _machineAddr = address(machine);
    }
}

contract Whitelist_WhitelistMachineDepositor_Util_Concrete_Test is
    Whitelist_Unit_Concrete_Test,
    WhitelistMachineDepositor_Util_Concrete_Test
{
    function setUp() public override(Whitelist_Unit_Concrete_Test, WhitelistMachineDepositor_Util_Concrete_Test) {
        WhitelistMachineDepositor_Util_Concrete_Test.setUp();
        whitelist = IWhitelist(address(whitelistMachineDepositor));

        vm.prank(dao);
        hubPeripheryFactory.setMachine(address(whitelistMachineDepositor), _machineAddr);
    }
}

contract Getters_Setters_WhitelistMachineDepositor_Util_Concrete_Test is
    Getter_Setter_MachinePeriphery_Util_Concrete_Test,
    WhitelistMachineDepositor_Util_Concrete_Test
{
    function setUp()
        public
        override(WhitelistMachineDepositor_Util_Concrete_Test, MachinePeriphery_Util_Concrete_Test)
    {
        WhitelistMachineDepositor_Util_Concrete_Test.setUp();
    }

    function test_authority_RevertWhen_MachineNotSet() public {
        vm.expectRevert(Errors.MachineNotSet.selector);
        whitelistMachineDepositor.authority();
    }

    function test_authority() public {
        vm.prank(dao);
        hubPeripheryFactory.setMachine(address(whitelistMachineDepositor), _machineAddr);

        assertEq(whitelistMachineDepositor.authority(), address(accessManager));
    }
}
