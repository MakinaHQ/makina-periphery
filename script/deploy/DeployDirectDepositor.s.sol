// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {IHubPeripheryFactory} from "../../src/interfaces/IHubPeripheryFactory.sol";

import {DeployInstance} from "./base/DeployInstance.s.sol";

/// @notice Builds the `HubPeripheryFactory.createDepositor` call for a new direct depositor, then broadcasts it or
///         logs it. See `DeployInstance` for modes and env vars.
///
/// Env vars (unless `setParams` and `setImplemId` were called):
///   HUB_PERIPHERY_OUTPUT_FILENAME - hub periphery output file holding the HubPeripheryFactory address
///                                   (under script/deploy/outputs/hub-peripheries/)
///   HUB_PERIPHERY_INPUT_FILENAME  - implementation ids input file (under script/deploy/inputs/implem-ids/)
///   HUB_STRAT_INPUT_FILENAME      - direct depositor init params input file
///                                   (under script/deploy/inputs/depositors/direct-depositors/)
///   HUB_STRAT_OUTPUT_FILENAME     - file to write the direct depositor address to
///                                   (under script/deploy/outputs/depositors/direct-depositors/, broadcast mode only)
///   VIEW_MODE (optional)          - true for view mode, unset or false for broadcast mode
contract DeployDirectDepositor is DeployInstance {
    function _createCall() internal view override returns (Call memory) {
        bool whitelistStatus = vm.parseJsonBool(inputJson, ".whitelistStatus");
        bool sanctionsCheckStatus = vm.parseJsonBool(inputJson, ".sanctionsCheckStatus");

        return Call({
            label: "HubPeripheryFactory.createDepositor",
            target: peripheryFactory,
            data: abi.encodeCall(
                IHubPeripheryFactory.createDepositor, (implemId, abi.encode(whitelistStatus, sanctionsCheckStatus))
            )
        });
    }

    function _writeOutput() internal override {
        string memory key = "key-deploy-direct-depositor-output-file";
        vm.writeJson(vm.serializeAddress(key, "DirectDepositor", deployedInstance), outputPath);
    }

    function _recordDir() internal pure override returns (string memory) {
        return "depositors/direct-depositors";
    }

    function _loadParamsFromEnv() internal override {
        setImplemId(_implemIdFromRecord(vm.envString("HUB_PERIPHERY_INPUT_FILENAME"), ".directDepositorImplemId"));
        setParams(
            _peripheryFactoryFromRecord(vm.envString("HUB_PERIPHERY_OUTPUT_FILENAME")),
            vm.envString("HUB_STRAT_INPUT_FILENAME"),
            _outputFilenameFromEnv("HUB_STRAT_OUTPUT_FILENAME")
        );
    }
}
