// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Machine} from "@makina-core/machine/Machine.sol";
import {MockFeeManager} from "@makina-core-test/mocks/MockFeeManager.sol";

import {MachineShareOracle} from "src/oracles/MachineShareOracle.sol";

import {Unit_Concrete_Test} from "../UnitConcrete.t.sol";

abstract contract MachineShareOracle_Unit_Concrete_Test is Unit_Concrete_Test {
    MockFeeManager public feeManager;

    Machine public machine;

    MachineShareOracle public machineShareOracle;

    uint8 public atDecimals;

    function setUp() public virtual override {
        Unit_Concrete_Test.setUp();

        atDecimals = accountingToken.decimals();

        feeManager = new MockFeeManager(dao, 0, 0);

        (machine,) = _deployMachine(address(accountingToken), address(this), address(this), address(feeManager));

        vm.prank(dao);
        machineShareOracle =
            MachineShareOracle(machineShareOracleFactory.createMachineShareOracle(address(machine), atDecimals));
    }
}

contract Getters_Setters_MachineShareOracle_Unit_Concrete_Test is MachineShareOracle_Unit_Concrete_Test {
    function test_Getters() public view {
        assertEq(machineShareOracle.decimals(), atDecimals);
        assertEq(machineShareOracle.description(), string.concat(DEFAULT_MACHINE_SHARE_TOKEN_SYMBOL, " / ACT"));
    }
}
