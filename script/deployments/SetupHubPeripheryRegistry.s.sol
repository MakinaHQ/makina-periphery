// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {IHubPeripheryRegistry} from "../../src/interfaces/IHubPeripheryRegistry.sol";

import {SetupHubPeriphery} from "./SetupHubPeriphery.s.sol";

/// @notice Wires the HubPeripheryRegistry deployed by `DeployHubPeriphery`: the periphery factory, the security module
///         beacon and the machine periphery component beacons under their implementation ids. See `SetupHubPeriphery`
///         for modes and env vars.
/// @dev The registry setters are restricted to INFRA_UPGRADE_ROLE once `SetupHubPeripheryAM` has run, to ADMIN_ROLE
///      before.
///
/// Env vars (unless `setFilenames` and `setImplemIdsFilename` were called):
///   HUB_PERIPHERY_INPUT_FILENAME  - hub periphery input file (under script/deployments/inputs/hub-peripheries/),
///                                   also naming the implementation ids input file
///                                   (under script/deployments/inputs/implem-ids/)
///   HUB_PERIPHERY_OUTPUT_FILENAME - hub periphery output file holding the deployed contract addresses
///                                   (under script/deployments/outputs/hub-peripheries/)
///   VIEW_MODE (optional)          - true for view mode, unset or false for broadcast mode
contract SetupHubPeripheryRegistry is SetupHubPeriphery {
    string public implemIdsJson;

    /// @dev Test hook to set the implementation ids filename explicitly, see `setFilenames`.
    function setImplemIdsFilename(string memory implemIdsFilename) public {
        implemIdsJson =
            vm.readFile(string.concat(vm.projectRoot(), "/script/deployments/inputs/implem-ids/", implemIdsFilename));
    }

    function _buildCalls() internal override {
        address registry = _deployed("HubPeripheryRegistry");

        _pushCall(
            "HubPeripheryRegistry.setPeripheryFactory",
            registry,
            abi.encodeCall(IHubPeripheryRegistry.setPeripheryFactory, (_deployed("HubPeripheryFactory")))
        );
        _pushCall(
            "HubPeripheryRegistry.setSecurityModuleBeacon",
            registry,
            abi.encodeCall(IHubPeripheryRegistry.setSecurityModuleBeacon, (_deployed("SecurityModuleBeacon")))
        );

        uint16 implemId = _implemId(".directDepositorImplemId");
        _pushCall(
            string.concat("HubPeripheryRegistry.setDepositorBeacon, implem id ", vm.toString(uint256(implemId))),
            registry,
            abi.encodeCall(IHubPeripheryRegistry.setDepositorBeacon, (implemId, _deployed("DirectDepositorBeacon")))
        );

        implemId = _implemId(".asyncRedeemerImplemId");
        _pushCall(
            string.concat("HubPeripheryRegistry.setRedeemerBeacon, implem id ", vm.toString(uint256(implemId))),
            registry,
            abi.encodeCall(IHubPeripheryRegistry.setRedeemerBeacon, (implemId, _deployed("AsyncRedeemerBeacon")))
        );

        implemId = _implemId(".asyncRedeemerFeeImplemId");
        _pushCall(
            string.concat("HubPeripheryRegistry.setRedeemerBeacon, implem id ", vm.toString(uint256(implemId))),
            registry,
            abi.encodeCall(IHubPeripheryRegistry.setRedeemerBeacon, (implemId, _deployed("AsyncRedeemerFeeBeacon")))
        );

        implemId = _implemId(".watermarkFeeManagerImplemId");
        _pushCall(
            string.concat("HubPeripheryRegistry.setFeeManagerBeacon, implem id ", vm.toString(uint256(implemId))),
            registry,
            abi.encodeCall(
                IHubPeripheryRegistry.setFeeManagerBeacon, (implemId, _deployed("WatermarkFeeManagerBeacon"))
            )
        );
    }

    function _loadFilenamesFromEnv() internal override {
        super._loadFilenamesFromEnv();
        setImplemIdsFilename(vm.envString("HUB_PERIPHERY_INPUT_FILENAME"));
    }

    function _implemId(string memory key) internal view returns (uint16) {
        return uint16(vm.parseJsonUint(implemIdsJson, key));
    }
}
