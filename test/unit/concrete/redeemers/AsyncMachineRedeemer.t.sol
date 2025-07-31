// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Machine} from "@makina-core/machine/Machine.sol";

import {IMachinePeriphery} from "src/interfaces/IMachinePeriphery.sol";
import {AsyncMachineRedeemer} from "src/redeemers/AsyncMachineRedeemer.sol";

import {
    MachinePeriphery_Util_Concrete_Test,
    Getter_Setter_MachinePeriphery_Util_Concrete_Test
} from "../machine-periphery/MachinePeriphery.t.sol";
import {Unit_Concrete_Test} from "../UnitConcrete.t.sol";

abstract contract AsyncMachineRedeemer_Util_Concrete_Test is MachinePeriphery_Util_Concrete_Test {
    AsyncMachineRedeemer public asyncMachineRedeemer;

    function setUp() public virtual override {
        Unit_Concrete_Test.setUp();

        vm.prank(dao);
        asyncMachineRedeemer =
            AsyncMachineRedeemer(hubPeripheryFactory.createMachineRedeemer(ASYNC_REDEEM_MANAGER_IMPLEM_ID, ""));

        machinePeriphery = IMachinePeriphery(address(asyncMachineRedeemer));

        (Machine machine,) =
            _deployMachine(address(accountingToken), address(0), address(asyncMachineRedeemer), address(0));
        _machineAddr = address(machine);
    }
}

contract Getters_Setters_AsyncMachineRedeemer_Util_Concrete_Test is
    Getter_Setter_MachinePeriphery_Util_Concrete_Test,
    AsyncMachineRedeemer_Util_Concrete_Test
{
    function setUp() public override(AsyncMachineRedeemer_Util_Concrete_Test, MachinePeriphery_Util_Concrete_Test) {
        AsyncMachineRedeemer_Util_Concrete_Test.setUp();
        machinePeriphery = IMachinePeriphery(address(asyncMachineRedeemer));
    }

    function test_Getters() public view {
        assertEq(asyncMachineRedeemer.nextRequestId(), 1);
        assertEq(asyncMachineRedeemer.lastFinalizedRequestId(), 0);
    }
}
