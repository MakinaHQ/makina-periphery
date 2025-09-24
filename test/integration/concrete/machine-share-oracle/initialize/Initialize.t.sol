// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";

import {CoreErrors} from "src/libraries/Errors.sol";
import {IMachineShareOracle} from "src/interfaces/IMachineShareOracle.sol";

import {MachineShareOracle_Integration_Concrete_Test} from "../MachineShareOracle.t.sol";

contract Initialize_Integration_Concrete_Test is MachineShareOracle_Integration_Concrete_Test {
    function test_RevertWhen_InvalidShareOwner() public {
        vm.expectRevert(abi.encodeWithSelector(IMachineShareOracle.InvalidShareOwner.selector));
        new BeaconProxy(
            address(machineShareOracleBeacon), abi.encodeCall(IMachineShareOracle.initialize, (address(0), atDecimals))
        );
    }

    function test_RevertWhen_PdvMigrated() public withPdvMigrated {
        vm.expectRevert(abi.encodeWithSelector(CoreErrors.Migrated.selector));
        new BeaconProxy(
            address(machineShareOracleBeacon),
            abi.encodeCall(IMachineShareOracle.initialize, (address(preDepositVault), atDecimals))
        );
    }

    function test_RevertWhen_InvalidDecimals() public {
        vm.expectRevert(abi.encodeWithSelector(CoreErrors.InvalidDecimals.selector));
        new BeaconProxy(
            address(machineShareOracleBeacon),
            abi.encodeCall(IMachineShareOracle.initialize, (address(preDepositVault), atDecimals - 1))
        );
    }
}
