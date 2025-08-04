// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Machine} from "@makina-core/machine/Machine.sol";

import {CoreErrors} from "src/libraries/Errors.sol";
import {IAsyncMachineRedeemer} from "src/interfaces/IAsyncMachineRedeemer.sol";
import {IMachinePeriphery} from "src/interfaces/IMachinePeriphery.sol";
import {AsyncMachineRedeemer} from "src/redeemers/AsyncMachineRedeemer.sol";

import {Constants} from "../../../utils/Constants.sol";

import {
    MachinePeriphery_Util_Concrete_Test,
    Getter_Setter_MachinePeriphery_Util_Concrete_Test
} from "../machine-periphery/MachinePeriphery.t.sol";
import {Unit_Concrete_Test} from "../UnitConcrete.t.sol";

abstract contract AsyncMachineRedeemer_Util_Concrete_Test is MachinePeriphery_Util_Concrete_Test {
    IAsyncMachineRedeemer public asyncMachineRedeemer;

    function setUp() public virtual override {
        Unit_Concrete_Test.setUp();

        vm.prank(dao);
        asyncMachineRedeemer = AsyncMachineRedeemer(
            hubPeripheryFactory.createMachineRedeemer(
                ASYNC_REDEEM_MANAGER_IMPLEM_ID, abi.encode(Constants.DEFAULT_FINALIZATION_DELAY)
            )
        );

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
    function setUp()
        public
        virtual
        override(AsyncMachineRedeemer_Util_Concrete_Test, MachinePeriphery_Util_Concrete_Test)
    {
        AsyncMachineRedeemer_Util_Concrete_Test.setUp();
    }

    modifier withMachine(address _machine) {
        vm.prank(dao);
        hubPeripheryFactory.setMachine(address(asyncMachineRedeemer), _machine);

        _;
    }

    function test_Getters() public view {
        assertEq(asyncMachineRedeemer.nextRequestId(), 1);
        assertEq(asyncMachineRedeemer.lastFinalizedRequestId(), 0);
        assertEq(asyncMachineRedeemer.finalizationDelay(), Constants.DEFAULT_FINALIZATION_DELAY);
    }

    function test_SetFinalizationDelay_RevertWhen_NotRM() public withMachine(_machineAddr) {
        vm.expectRevert(CoreErrors.UnauthorizedCaller.selector);
        asyncMachineRedeemer.setFinalizationDelay(1 days);
    }

    function test_SetFinalizationDelay() public withMachine(_machineAddr) {
        uint256 newFinalizationDelay = 7 days;
        vm.expectEmit(true, true, false, false, address(asyncMachineRedeemer));
        emit IAsyncMachineRedeemer.FinalizationDelayChanged(Constants.DEFAULT_FINALIZATION_DELAY, newFinalizationDelay);
        vm.prank(riskManager);
        asyncMachineRedeemer.setFinalizationDelay(newFinalizationDelay);
        assertEq(asyncMachineRedeemer.finalizationDelay(), newFinalizationDelay);
    }
}
