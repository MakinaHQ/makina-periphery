// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {IAccessManager} from "@openzeppelin/contracts/access/manager/IAccessManager.sol";
import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";

import {FlashloanAggregator} from "../../src/flashloans/FlashloanAggregator.sol";
import {HubPeripheryFactory} from "../../src/factories/HubPeripheryFactory.sol";
import {HubPeripheryRegistry} from "../../src/registries/HubPeripheryRegistry.sol";
import {MachineShareOracleFactory} from "../../src/factories/MachineShareOracleFactory.sol";
import {MetaMorphoOracleFactory} from "../../src/factories/MetaMorphoOracleFactory.sol";

import {SetupHubPeriphery} from "./base/SetupHubPeriphery.s.sol";

/// @notice Sets the AccessManager function roles of the hub periphery deployed by `DeployHubPeriphery`, as listed by
///         `Base.hubPeripheryAMFunctionRoles`. See `SetupHubPeriphery` for modes and env vars.
/// @dev Every call requires ADMIN_ROLE on the hub AccessManager.
///
/// Env vars (unless `setFilenames` was called):
///   HUB_PERIPHERY_INPUT_FILENAME  - hub periphery input file holding the AccessManager address
///                                   (under script/deploy/inputs/hub-peripheries/)
///   HUB_PERIPHERY_OUTPUT_FILENAME - hub periphery output file holding the deployed contract addresses
///                                   (under script/deploy/outputs/hub-peripheries/)
///   VIEW_MODE (optional)          - true for view mode, unset or false for broadcast mode
contract SetupHubPeripheryAM is SetupHubPeriphery {
    function _buildCalls() internal override {
        address accessManager = vm.parseJsonAddress(inputJson, ".accessManager");

        AMFunctionRole[] memory functionRoles = hubPeripheryAMFunctionRoles(_deployedHubPeriphery());
        for (uint256 i; i < functionRoles.length; ++i) {
            _pushCall(
                string.concat("AccessManager.setTargetFunctionRole ", functionRoles[i].targetName),
                accessManager,
                abi.encodeCall(
                    IAccessManager.setTargetFunctionRole,
                    (functionRoles[i].target, functionRoles[i].selectors, functionRoles[i].roleId)
                )
            );
        }
    }

    /// @dev The hub periphery of the output file.
    function _deployedHubPeriphery() internal view returns (HubPeriphery memory) {
        return HubPeriphery({
            flashloanAggregator: FlashloanAggregator(_deployed("FlashloanAggregator")),
            hubPeripheryRegistry: HubPeripheryRegistry(_deployed("HubPeripheryRegistry")),
            hubPeripheryFactory: HubPeripheryFactory(_deployed("HubPeripheryFactory")),
            directDepositorBeacon: UpgradeableBeacon(_deployed("DirectDepositorBeacon")),
            asyncRedeemerBeacon: UpgradeableBeacon(_deployed("AsyncRedeemerBeacon")),
            asyncRedeemerFeeBeacon: UpgradeableBeacon(_deployed("AsyncRedeemerFeeBeacon")),
            watermarkFeeManagerBeacon: UpgradeableBeacon(_deployed("WatermarkFeeManagerBeacon")),
            securityModuleBeacon: UpgradeableBeacon(_deployed("SecurityModuleBeacon")),
            metaMorphoOracleFactory: MetaMorphoOracleFactory(_deployed("MetaMorphoOracleFactory")),
            machineShareOracleBeacon: UpgradeableBeacon(_deployed("MachineShareOracleBeacon")),
            machineShareOracleFactory: MachineShareOracleFactory(_deployed("MachineShareOracleFactory"))
        });
    }
}
