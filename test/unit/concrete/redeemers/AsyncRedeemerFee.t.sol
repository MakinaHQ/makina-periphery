// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {Machine} from "@makina-core/machine/Machine.sol";

import {Errors, CoreErrors} from "src/libraries/Errors.sol";
import {IAsyncRedeemer} from "src/interfaces/IAsyncRedeemer.sol";
import {IAsyncRedeemerFee} from "src/interfaces/IAsyncRedeemerFee.sol";
import {IMachinePeriphery} from "src/interfaces/IMachinePeriphery.sol";
import {IWhitelist} from "src/interfaces/IWhitelist.sol";

import {
    MachinePeriphery_Util_Concrete_Test,
    Getter_Setter_MachinePeriphery_Util_Concrete_Test
} from "../machine-periphery/MachinePeriphery.t.sol";
import {Whitelist_Unit_Concrete_Test} from "../whitelist/Whitelist.t.sol";
import {Unit_Concrete_Test} from "../UnitConcrete.t.sol";

abstract contract AsyncRedeemerFee_Util_Concrete_Test is MachinePeriphery_Util_Concrete_Test {
    IAsyncRedeemerFee internal asyncRedeemerFee;
    Machine internal machine;

    function setUp() public virtual override {
        Unit_Concrete_Test.setUp();

        vm.prank(dao);
        asyncRedeemerFee = IAsyncRedeemerFee(
            hubPeripheryFactory.createRedeemer(
                ASYNC_REDEEMER_FEE_IMPLEM_ID,
                abi.encode(
                    DEFAULT_FINALIZATION_DELAY,
                    DEFAULT_MIN_REDEEM_AMOUNT,
                    DEFAULT_INITIAL_WHITELIST_STATUS,
                    DEFAULT_REDEEM_FEE_RATE,
                    DEFAULT_MAX_REDEEM_FEE_RATE
                )
            )
        );

        machinePeriphery = IMachinePeriphery(address(asyncRedeemerFee));

        (machine,) = _deployMachine(address(accountingToken), address(0), address(asyncRedeemerFee), address(0));
    }
}

contract Whitelist_AsyncRedeemerFee_Util_Concrete_Test is
    Whitelist_Unit_Concrete_Test,
    AsyncRedeemerFee_Util_Concrete_Test
{
    function setUp() public override(Whitelist_Unit_Concrete_Test, AsyncRedeemerFee_Util_Concrete_Test) {
        AsyncRedeemerFee_Util_Concrete_Test.setUp();
        whitelist = IWhitelist(address(asyncRedeemerFee));

        vm.prank(dao);
        hubPeripheryFactory.setMachine(address(asyncRedeemerFee), address(machine));
    }
}

contract Getters_Setters_AsyncRedeemerFee_Util_Concrete_Test is
    Getter_Setter_MachinePeriphery_Util_Concrete_Test,
    AsyncRedeemerFee_Util_Concrete_Test
{
    function setUp() public virtual override(AsyncRedeemerFee_Util_Concrete_Test, MachinePeriphery_Util_Concrete_Test) {
        AsyncRedeemerFee_Util_Concrete_Test.setUp();
    }

    modifier withMachine(address _machine) {
        vm.prank(dao);
        hubPeripheryFactory.setMachine(address(asyncRedeemerFee), _machine);

        _;
    }

    function test_Getters() public view {
        assertEq(asyncRedeemerFee.nextRequestId(), 1);
        assertEq(asyncRedeemerFee.lastFinalizedRequestId(), 0);
        assertEq(asyncRedeemerFee.finalizationDelay(), DEFAULT_FINALIZATION_DELAY);
        assertEq(asyncRedeemerFee.minRedeemAmount(), DEFAULT_MIN_REDEEM_AMOUNT);
        assertEq(asyncRedeemerFee.redeemFeeRate(), DEFAULT_REDEEM_FEE_RATE);
        assertEq(asyncRedeemerFee.maxRedeemFeeRate(), DEFAULT_MAX_REDEEM_FEE_RATE);
    }

    function test_SetFinalizationDelay_RevertWhen_NotRMT() public withMachine(address(machine)) {
        vm.expectRevert(CoreErrors.UnauthorizedCaller.selector);
        asyncRedeemerFee.setFinalizationDelay(1 days);
    }

    function test_SetFinalizationDelay() public withMachine(address(machine)) {
        uint256 newFinalizationDelay = 7 days;
        vm.expectEmit(true, true, false, false, address(asyncRedeemerFee));
        emit IAsyncRedeemer.FinalizationDelayChanged(DEFAULT_FINALIZATION_DELAY, newFinalizationDelay);
        vm.prank(riskManagerTimelock);
        asyncRedeemerFee.setFinalizationDelay(newFinalizationDelay);
        assertEq(asyncRedeemerFee.finalizationDelay(), newFinalizationDelay);
    }

    function test_SetMinRedeemAmount_RevertWhen_NotRMT() public withMachine(address(machine)) {
        vm.expectRevert(CoreErrors.UnauthorizedCaller.selector);
        asyncRedeemerFee.setMinRedeemAmount(10);
    }

    function test_SetMinRedeemAmount() public withMachine(address(machine)) {
        uint256 newMinRedeemAmount = 10;
        vm.expectEmit(true, true, false, false, address(asyncRedeemerFee));
        emit IAsyncRedeemer.MinRedeemAmountChanged(DEFAULT_MIN_REDEEM_AMOUNT, newMinRedeemAmount);
        vm.prank(riskManagerTimelock);
        asyncRedeemerFee.setMinRedeemAmount(newMinRedeemAmount);
        assertEq(asyncRedeemerFee.minRedeemAmount(), newMinRedeemAmount);
    }

    function test_SetRedeemFeeRate_RevertWhen_NotRMT() public withMachine(address(machine)) {
        vm.expectRevert(CoreErrors.UnauthorizedCaller.selector);
        asyncRedeemerFee.setRedeemFeeRate(0);
    }

    function test_SetRedeemFeeRate_RevertWhen_MaxFeeRateValueExceeded() public withMachine(address(machine)) {
        vm.expectRevert(Errors.MaxFeeRateValueExceeded.selector);
        vm.prank(riskManagerTimelock);
        asyncRedeemerFee.setRedeemFeeRate(DEFAULT_MAX_REDEEM_FEE_RATE + 1);
    }

    function test_SetRedeemFeeRate() public withMachine(address(machine)) {
        uint256 newRedeemFeeRate = 5e15; // 0.5% fee
        vm.expectEmit(true, true, false, false, address(asyncRedeemerFee));
        emit IAsyncRedeemerFee.RedeemFeeRateChanged(DEFAULT_REDEEM_FEE_RATE, newRedeemFeeRate);
        vm.prank(riskManagerTimelock);
        asyncRedeemerFee.setRedeemFeeRate(newRedeemFeeRate);
        assertEq(asyncRedeemerFee.redeemFeeRate(), newRedeemFeeRate);
    }
}
