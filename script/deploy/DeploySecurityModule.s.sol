// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {IHubPeripheryFactory} from "../../src/interfaces/IHubPeripheryFactory.sol";

import {DeployInstance} from "./base/DeployInstance.s.sol";

/// @notice Builds the `HubPeripheryFactory.createSecurityModule` call for a new security module, then broadcasts it
///         or logs it. See `DeployInstance` for modes and env vars.
///
/// Env vars (unless `setParams` was called):
///   HUB_PERIPHERY_OUTPUT_FILENAME - hub periphery output file holding the HubPeripheryFactory address
///                                   (under script/deploy/outputs/hub-peripheries/)
///   HUB_STRAT_INPUT_FILENAME      - security module init params input file
///                                   (under script/deploy/inputs/security-modules/)
///   HUB_STRAT_OUTPUT_FILENAME     - file to write the security module address to
///                                   (under script/deploy/outputs/security-modules/, broadcast mode only)
///   VIEW_MODE (optional)          - true for view mode, unset or false for broadcast mode
contract DeploySecurityModule is DeployInstance {
    function _createCall() internal view override returns (Call memory) {
        return Call({
            label: "HubPeripheryFactory.createSecurityModule",
            target: peripheryFactory,
            data: abi.encodeCall(IHubPeripheryFactory.createSecurityModule, (parseSecurityModuleInitParams(inputJson)))
        });
    }

    function _writeOutput() internal override {
        string memory key = "key-deploy-security-module-output-file";
        vm.writeJson(vm.serializeAddress(key, "SecurityModule", deployedInstance), outputPath);
    }

    function _recordDir() internal pure override returns (string memory) {
        return "security-modules";
    }

    function _loadParamsFromEnv() internal override {
        setParams(
            _peripheryFactoryFromRecord(vm.envString("HUB_PERIPHERY_OUTPUT_FILENAME")),
            vm.envString("HUB_STRAT_INPUT_FILENAME"),
            _outputFilenameFromEnv("HUB_STRAT_OUTPUT_FILENAME")
        );
    }
}
