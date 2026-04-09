// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {Machine} from "@makina-core/machine/Machine.sol";

import {CoreErrors} from "src/libraries/Errors.sol";
import {IAsyncRedeemer} from "src/interfaces/IAsyncRedeemer.sol";
import {IMachinePeriphery} from "src/interfaces/IMachinePeriphery.sol";
import {IWhitelist} from "src/interfaces/IWhitelist.sol";
import {AsyncRedeemer} from "src/redeemers/AsyncRedeemer.sol";

import {
    MachinePeriphery_Util_Concrete_Test,
    Getter_Setter_MachinePeriphery_Util_Concrete_Test
} from "../machine-periphery/MachinePeriphery.t.sol";
import {Whitelist_Unit_Concrete_Test} from "../whitelist/Whitelist.t.sol";
import {Unit_Concrete_Test} from "../UnitConcrete.t.sol";

abstract contract AsyncRedeemer_Util_Concrete_Test is MachinePeriphery_Util_Concrete_Test {
    IAsyncRedeemer internal asyncRedeemer;
    Machine internal machine;

    function setUp() public virtual override {
        Unit_Concrete_Test.setUp();

        vm.prank(dao);
        asyncRedeemer = AsyncRedeemer(
            hubPeripheryFactory.createRedeemer(
                ASYNC_REDEEMER_IMPLEM_ID,
                abi.encode(DEFAULT_FINALIZATION_DELAY, DEFAULT_MIN_REDEEM_AMOUNT, DEFAULT_INITIAL_WHITELIST_STATUS)
            )
        );

        machinePeriphery = IMachinePeriphery(address(asyncRedeemer));

        (machine,) = _deployMachine(address(accountingToken), address(0), address(asyncRedeemer), address(0));
    }
}

contract Whitelist_AsyncRedeemer_Util_Concrete_Test is Whitelist_Unit_Concrete_Test, AsyncRedeemer_Util_Concrete_Test {
    function setUp() public override(Whitelist_Unit_Concrete_Test, AsyncRedeemer_Util_Concrete_Test) {
        AsyncRedeemer_Util_Concrete_Test.setUp();
        whitelist = IWhitelist(address(asyncRedeemer));

        vm.prank(dao);
        hubPeripheryFactory.setMachine(address(asyncRedeemer), address(machine));
    }
}

contract Getters_Setters_AsyncRedeemer_Util_Concrete_Test is
    Getter_Setter_MachinePeriphery_Util_Concrete_Test,
    AsyncRedeemer_Util_Concrete_Test
{
    function setUp() public virtual override(AsyncRedeemer_Util_Concrete_Test, MachinePeriphery_Util_Concrete_Test) {
        AsyncRedeemer_Util_Concrete_Test.setUp();
    }

    modifier withMachine(address _machine) {
        vm.prank(dao);
        hubPeripheryFactory.setMachine(address(asyncRedeemer), _machine);

        _;
    }

    function test_Getters() public view {
        assertEq(asyncRedeemer.nextRequestId(), 1);
        assertEq(asyncRedeemer.lastFinalizedRequestId(), 0);
        assertEq(asyncRedeemer.finalizationDelay(), DEFAULT_FINALIZATION_DELAY);
        assertEq(asyncRedeemer.minRedeemAmount(), DEFAULT_MIN_REDEEM_AMOUNT);
    }

    function test_SetFinalizationDelay_RevertWhen_NotRMT() public withMachine(address(machine)) {
        vm.expectRevert(CoreErrors.UnauthorizedCaller.selector);
        asyncRedeemer.setFinalizationDelay(1 days);
    }

    function test_SetFinalizationDelay() public withMachine(address(machine)) {
        uint256 newFinalizationDelay = 7 days;
        vm.expectEmit(true, true, false, false, address(asyncRedeemer));
        emit IAsyncRedeemer.FinalizationDelayChanged(DEFAULT_FINALIZATION_DELAY, newFinalizationDelay);
        vm.prank(riskManagerTimelock);
        asyncRedeemer.setFinalizationDelay(newFinalizationDelay);
        assertEq(asyncRedeemer.finalizationDelay(), newFinalizationDelay);
    }

    function test_SetMinRedeemAmount_RevertWhen_NotRMT() public withMachine(address(machine)) {
        vm.expectRevert(CoreErrors.UnauthorizedCaller.selector);
        asyncRedeemer.setMinRedeemAmount(10);
    }

    function test_SetMinRedeemAmount() public withMachine(address(machine)) {
        uint256 newMinRedeemAmount = 10;
        vm.expectEmit(true, true, false, false, address(asyncRedeemer));
        emit IAsyncRedeemer.MinRedeemAmountChanged(DEFAULT_MIN_REDEEM_AMOUNT, newMinRedeemAmount);
        vm.prank(riskManagerTimelock);
        asyncRedeemer.setMinRedeemAmount(newMinRedeemAmount);
        assertEq(asyncRedeemer.minRedeemAmount(), newMinRedeemAmount);
    }
}
