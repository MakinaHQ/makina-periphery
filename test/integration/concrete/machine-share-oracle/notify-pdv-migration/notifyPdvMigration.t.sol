// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {CoreErrors} from "src/libraries/Errors.sol";
import {IMachineShareOracle} from "src/interfaces/IMachineShareOracle.sol";
import {MachineShareOracle} from "src/oracles/MachineShareOracle.sol";

import {MachineShareOracle_Integration_Concrete_Test} from "../MachineShareOracle.t.sol";

contract NotifyPdvMigration_Integration_Concrete_Test is MachineShareOracle_Integration_Concrete_Test {
    function test_RevertGiven_ShareOwnerNotPreDepositVault() public withPdvMigrated {
        vm.prank(dao);
        machineShareOracle =
            MachineShareOracle(machineShareOracleFactory.createMachineShareOracle(address(machine), atDecimals));

        vm.expectRevert(abi.encodeWithSelector(CoreErrors.NotPreDepositVault.selector));
        machineShareOracle.notifyPdvMigration();
    }

    function test_RevertGiven_MigrationAlreadyNotified() public {
        vm.prank(dao);
        machineShareOracle =
            MachineShareOracle(machineShareOracleFactory.createMachineShareOracle(address(preDepositVault), atDecimals));

        _deployMachineFromPreDeposit(address(preDepositVault), address(this), address(this), address(feeManager));

        machineShareOracle.notifyPdvMigration();

        vm.expectRevert(abi.encodeWithSelector(CoreErrors.NotPreDepositVault.selector));
        machineShareOracle.notifyPdvMigration();
    }

    function test_RevertGiven_PreDepositVaultNotMigrated() public {
        vm.prank(dao);
        machineShareOracle =
            MachineShareOracle(machineShareOracleFactory.createMachineShareOracle(address(preDepositVault), atDecimals));

        vm.expectRevert(abi.encodeWithSelector(CoreErrors.NotMigrated.selector));
        machineShareOracle.notifyPdvMigration();
    }

    function test_NotifyPdvMigration() public {
        vm.prank(dao);
        machineShareOracle =
            MachineShareOracle(machineShareOracleFactory.createMachineShareOracle(address(preDepositVault), atDecimals));

        (machine,) =
            _deployMachineFromPreDeposit(address(preDepositVault), address(this), address(this), address(feeManager));

        vm.expectEmit(true, true, false, false, address(machineShareOracle));
        emit IMachineShareOracle.ShareOwnerMigrated(address(preDepositVault), address(machine));
        machineShareOracle.notifyPdvMigration();

        assertEq(machineShareOracle.shareOwner(), address(machine));
    }
}
