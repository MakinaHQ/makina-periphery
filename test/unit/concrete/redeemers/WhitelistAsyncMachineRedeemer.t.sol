// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Machine} from "@makina-core/machine/Machine.sol";

import {Errors} from "src/libraries/Errors.sol";
import {IMachinePeriphery} from "src/interfaces/IMachinePeriphery.sol";
import {IWhitelist} from "src/interfaces/IWhitelist.sol";
import {WhitelistAsyncMachineRedeemer} from "src/redeemers/WhitelistAsyncMachineRedeemer.sol";

import {
    MachinePeriphery_Util_Concrete_Test,
    Getter_Setter_MachinePeriphery_Util_Concrete_Test
} from "../machine-periphery/MachinePeriphery.t.sol";
import {Whitelist_Unit_Concrete_Test} from "../whitelist/Whitelist.t.sol";
import {Unit_Concrete_Test} from "../UnitConcrete.t.sol";

abstract contract WhitelistAsyncMachineRedeemer_Util_Concrete_Test is MachinePeriphery_Util_Concrete_Test {
    WhitelistAsyncMachineRedeemer public whitelistAsyncMachineRedeemer;

    function setUp() public virtual override {
        Unit_Concrete_Test.setUp();

        vm.prank(dao);
        whitelistAsyncMachineRedeemer = WhitelistAsyncMachineRedeemer(
            hubPeripheryFactory.createMachineRedeemer(WHITELISTED_ASYNC_REDEEM_MANAGER_IMPLEM_ID, "")
        );

        (Machine machine,) =
            _deployMachine(address(accountingToken), address(0), address(whitelistAsyncMachineRedeemer), address(0));
        _machineAddr = address(machine);
    }
}

contract Whitelist_WhitelistAsyncMachineRedeemer_Util_Concrete_Test is
    Whitelist_Unit_Concrete_Test,
    WhitelistAsyncMachineRedeemer_Util_Concrete_Test
{
    function setUp() public override(Whitelist_Unit_Concrete_Test, WhitelistAsyncMachineRedeemer_Util_Concrete_Test) {
        WhitelistAsyncMachineRedeemer_Util_Concrete_Test.setUp();
        whitelist = IWhitelist(address(whitelistAsyncMachineRedeemer));

        vm.prank(address(hubPeripheryFactory));
        whitelistAsyncMachineRedeemer.setMachine(_machineAddr);
    }
}

contract Getters_Setters_WhitelistAsyncMachineRedeemer_Util_Concrete_Test is
    Getter_Setter_MachinePeriphery_Util_Concrete_Test,
    WhitelistAsyncMachineRedeemer_Util_Concrete_Test
{
    function setUp()
        public
        override(WhitelistAsyncMachineRedeemer_Util_Concrete_Test, MachinePeriphery_Util_Concrete_Test)
    {
        WhitelistAsyncMachineRedeemer_Util_Concrete_Test.setUp();
        machinePeriphery = IMachinePeriphery(address(whitelistAsyncMachineRedeemer));
    }

    function test_Getters() public view {
        assertEq(whitelistAsyncMachineRedeemer.nextRequestId(), 1);
        assertEq(whitelistAsyncMachineRedeemer.lastFinalizedRequestId(), 0);
    }

    function test_authority_RevertWhen_MachineNotSet() public {
        vm.expectRevert(Errors.MachineNotSet.selector);
        whitelistAsyncMachineRedeemer.authority();
    }

    function test_authority() public {
        vm.prank(address(hubPeripheryFactory));
        whitelistAsyncMachineRedeemer.setMachine(_machineAddr);

        assertEq(whitelistAsyncMachineRedeemer.authority(), address(accessManager));
    }
}
