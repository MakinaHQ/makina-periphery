// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {IAccessManaged} from "@openzeppelin/contracts/access/manager/IAccessManaged.sol";

import {IMachineShareOracle} from "src/interfaces/IMachineShareOracle.sol";
import {IMachineShareOracleFactory} from "src/interfaces/IMachineShareOracleFactory.sol";

import {MachineShareOracleFactory_Integration_Concrete_Test} from "../MachineShareOracleFactory.t.sol";

contract CreateMachineShareOracle_Integration_Concrete_Test is MachineShareOracleFactory_Integration_Concrete_Test {
    function test_CreateMachineShareOracle_RevertWhen_CallerWithoutRole() public {
        vm.expectRevert(abi.encodeWithSelector(IAccessManaged.AccessManagedUnauthorized.selector, address(this)));
        machineShareOracleFactory.createMachineShareOracle(address(0), 18);
    }

    function test_CreateMachineShareOracle_PreDepositVault() public {
        uint8 decimals = 18;

        vm.expectEmit(false, false, false, false, address(machineShareOracleFactory));
        emit IMachineShareOracleFactory.MachineShareOracleCreated(address(0));
        vm.prank(dao);
        address oracle = machineShareOracleFactory.createMachineShareOracle(address(preDepositVault), decimals);

        assertTrue(machineShareOracleFactory.isMachineShareOracle(oracle));
        assertEq(IMachineShareOracle(oracle).shareOwner(), address(preDepositVault));
        assertEq(IMachineShareOracle(oracle).decimals(), decimals);
    }

    function test_CreateMachineShareOracle_Machine() public withPdvMigrated {
        uint8 decimals = 18;

        vm.expectEmit(false, false, false, false, address(machineShareOracleFactory));
        emit IMachineShareOracleFactory.MachineShareOracleCreated(address(0));
        vm.prank(dao);
        address oracle = machineShareOracleFactory.createMachineShareOracle(address(machine), decimals);

        assertTrue(machineShareOracleFactory.isMachineShareOracle(oracle));
        assertEq(IMachineShareOracle(oracle).shareOwner(), address(machine));
        assertEq(IMachineShareOracle(oracle).decimals(), decimals);
    }
}
