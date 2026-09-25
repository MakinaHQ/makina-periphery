// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {console} from "forge-std/console.sol";

import {IHubPeripheryFactory} from "../../src/interfaces/IHubPeripheryFactory.sol";
import {IWatermarkFeeManager} from "../../src/interfaces/IWatermarkFeeManager.sol";

import {DeployInstance} from "./base/DeployInstance.s.sol";

/// @notice Builds the `HubPeripheryFactory.createFeeManager` call for a new watermark fee manager, then broadcasts it
///         or logs it. See `DeployInstance` for modes and env vars.
/// @dev A non-zero `securityModule` in the input file is wired to the created fee manager with
///      `HubPeripheryFactory.setSecurityModule`: broadcast right after the creation, or logged as a reminder in view
///      mode, since the fee manager address is not known before the creation is submitted.
///
/// Env vars (unless `setParams` and `setImplemId` were called):
///   HUB_PERIPHERY_OUTPUT_FILENAME - hub periphery output file holding the HubPeripheryFactory address
///                                   (under script/deploy/outputs/hub-peripheries/)
///   HUB_PERIPHERY_INPUT_FILENAME  - implementation ids input file (under script/deploy/inputs/implem-ids/)
///   HUB_STRAT_INPUT_FILENAME      - watermark fee manager init params input file
///                                   (under script/deploy/inputs/fee-managers/watermark-fee-managers/)
///   HUB_STRAT_OUTPUT_FILENAME     - file to write the watermark fee manager address to
///                                   (under script/deploy/outputs/fee-managers/watermark-fee-managers/,
///                                   broadcast mode only)
///   VIEW_MODE (optional)          - true for view mode, unset or false for broadcast mode
contract DeployWatermarkFeeManager is DeployInstance {
    function _createCall() internal view override returns (Call memory) {
        IWatermarkFeeManager.WatermarkFeeManagerInitParams memory initParams =
            parseWatermarkFeeManagerInitParams(inputJson, ".watermarkFeeManagerInitParams");

        return Call({
            label: "HubPeripheryFactory.createFeeManager",
            target: peripheryFactory,
            data: abi.encodeCall(IHubPeripheryFactory.createFeeManager, (implemId, abi.encode(initParams)))
        });
    }

    function _postCreate() internal override {
        address securityModule = _securityModule();
        if (securityModule != address(0)) {
            IHubPeripheryFactory(peripheryFactory).setSecurityModule(deployedInstance, securityModule);
        }
    }

    function _logPostCreate() internal view override {
        address securityModule = _securityModule();
        if (securityModule != address(0)) {
            console.log("Then, once the fee manager is created, submit HubPeripheryFactory.setSecurityModule with:");
            console.log("Fee manager: the created fee manager address");
            console.log("Security module:", securityModule);
            console.log("");
        }
    }

    function _writeOutput() internal override {
        string memory key = "key-deploy-watermark-fee-manager-output-file";
        vm.writeJson(vm.serializeAddress(key, "WatermarkFeeManager", deployedInstance), outputPath);
    }

    function _recordDir() internal pure override returns (string memory) {
        return "fee-managers/watermark-fee-managers";
    }

    function _loadParamsFromEnv() internal override {
        setImplemId(_implemIdFromRecord(vm.envString("HUB_PERIPHERY_INPUT_FILENAME"), ".watermarkFeeManagerImplemId"));
        setParams(
            _peripheryFactoryFromRecord(vm.envString("HUB_PERIPHERY_OUTPUT_FILENAME")),
            vm.envString("HUB_STRAT_INPUT_FILENAME"),
            _outputFilenameFromEnv("HUB_STRAT_OUTPUT_FILENAME")
        );
    }

    function _securityModule() internal view returns (address) {
        return vm.parseJsonAddress(inputJson, ".securityModule");
    }
}
