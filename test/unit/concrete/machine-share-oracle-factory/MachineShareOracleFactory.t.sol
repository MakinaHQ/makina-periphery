// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {IAccessManaged} from "@openzeppelin/contracts/access/manager/IAccessManaged.sol";

import {Machine} from "@makina-core/machine/Machine.sol";
import {MockFeeManager} from "@makina-core-test/mocks/MockFeeManager.sol";

import {IMachineShareOracleFactory} from "src/interfaces/IMachineShareOracleFactory.sol";

import {Unit_Concrete_Test} from "../UnitConcrete.t.sol";

abstract contract MachineShareOracleFactory_Unit_Concrete_Test is Unit_Concrete_Test {
    MockFeeManager public feeManager;

    Machine public machine;

    function setUp() public virtual override {
        Unit_Concrete_Test.setUp();

        feeManager = new MockFeeManager(dao, 0, 0);

        (machine,) = _deployMachine(address(accountingToken), address(this), address(this), address(feeManager));
    }
}

contract Getters_Setters_MachineShareOracleFactory_Unit_Concrete_Test is
    MachineShareOracleFactory_Unit_Concrete_Test
{
    function test_Getters() public view {
        assertEq(machineShareOracleFactory.authority(), address(accessManager));
        assertEq(machineShareOracleFactory.machineShareOracleBeacon(), address(machineShareOracleBeacon));
        assertFalse(machineShareOracleFactory.isMachineShareOracle(address(0)));
    }

    function test_SetMachineShareOracleBeacon_RevertWhen_CallerWithoutRole() public {
        vm.expectRevert(abi.encodeWithSelector(IAccessManaged.AccessManagedUnauthorized.selector, address(this)));
        machineShareOracleFactory.setMachineShareOracleBeacon(address(0));
    }

    function test_SetMachineShareOracleBeacon() public {
        address newMachineShareOracleBeacon = makeAddr("newMachineShareOracleBeacon");
        vm.expectEmit(true, true, false, false, address(machineShareOracleFactory));
        emit IMachineShareOracleFactory.MachineShareOracleBeaconChanged(
            address(machineShareOracleBeacon), newMachineShareOracleBeacon
        );
        vm.prank(dao);
        machineShareOracleFactory.setMachineShareOracleBeacon(newMachineShareOracleBeacon);
        assertEq(machineShareOracleFactory.machineShareOracleBeacon(), newMachineShareOracleBeacon);
    }
}
