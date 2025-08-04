// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {IAccessManaged} from "@openzeppelin/contracts/access/manager/IAccessManaged.sol";

import {Machine} from "@makina-core/machine/Machine.sol";

import {Errors} from "src/libraries/Errors.sol";
import {IAsyncMachineRedeemer} from "src/interfaces/IAsyncMachineRedeemer.sol";
import {IMachinePeriphery} from "src/interfaces/IMachinePeriphery.sol";
import {IWhitelist} from "src/interfaces/IWhitelist.sol";

import {Constants} from "../../../utils/Constants.sol";

import {
    AsyncMachineRedeemer_Util_Concrete_Test,
    Getters_Setters_AsyncMachineRedeemer_Util_Concrete_Test
} from "./AsyncMachineRedeemer.t.sol";
import {Whitelist_Unit_Concrete_Test} from "../whitelist/Whitelist.t.sol";
import {Unit_Concrete_Test} from "../UnitConcrete.t.sol";

abstract contract WhitelistAsyncMachineRedeemer_Util_Concrete_Test is AsyncMachineRedeemer_Util_Concrete_Test {
    function setUp() public virtual override {
        Unit_Concrete_Test.setUp();

        vm.prank(dao);
        asyncMachineRedeemer = IAsyncMachineRedeemer(
            hubPeripheryFactory.createMachineRedeemer(
                WHITELISTED_ASYNC_REDEEM_MANAGER_IMPLEM_ID, abi.encode(Constants.DEFAULT_FINALIZATION_DELAY)
            )
        );

        machinePeriphery = IMachinePeriphery(address(asyncMachineRedeemer));

        (Machine machine,) =
            _deployMachine(address(accountingToken), address(0), address(asyncMachineRedeemer), address(0));
        _machineAddr = address(machine);
    }
}

contract Whitelist_WhitelistAsyncMachineRedeemer_Util_Concrete_Test is
    Whitelist_Unit_Concrete_Test,
    WhitelistAsyncMachineRedeemer_Util_Concrete_Test
{
    function setUp() public override(Whitelist_Unit_Concrete_Test, WhitelistAsyncMachineRedeemer_Util_Concrete_Test) {
        WhitelistAsyncMachineRedeemer_Util_Concrete_Test.setUp();
        whitelist = IWhitelist(address(asyncMachineRedeemer));

        vm.prank(address(hubPeripheryFactory));
        asyncMachineRedeemer.setMachine(_machineAddr);
    }
}

contract Getters_Setters_WhitelistAsyncMachineRedeemer_Util_Concrete_Test is
    Getters_Setters_AsyncMachineRedeemer_Util_Concrete_Test,
    WhitelistAsyncMachineRedeemer_Util_Concrete_Test
{
    function setUp()
        public
        override(WhitelistAsyncMachineRedeemer_Util_Concrete_Test, Getters_Setters_AsyncMachineRedeemer_Util_Concrete_Test)
    {
        WhitelistAsyncMachineRedeemer_Util_Concrete_Test.setUp();
    }

    function test_authority_RevertWhen_MachineNotSet() public {
        vm.expectRevert(Errors.MachineNotSet.selector);
        IAccessManaged(address(asyncMachineRedeemer)).authority();
    }

    function test_authority() public withMachine(_machineAddr) {
        assertEq(IAccessManaged(address(asyncMachineRedeemer)).authority(), address(accessManager));
    }
}
