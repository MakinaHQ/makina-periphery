// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {DeployPeriphery} from "./base/DeployPeriphery.s.sol";

/// @notice Deploys the Makina hub periphery shared contracts, bound to the hub core and AccessManager named in the
///         input file. Their registry and AccessManager setup run separately, see `SetupHubPeripheryRegistry` and
///         `SetupHubPeripheryAM`.
///
/// Env vars (unless `setFilenames` was called):
///   HUB_PERIPHERY_INPUT_FILENAME  - hub periphery input file holding the deployment parameters
///                                   (under script/deploy/inputs/hub-peripheries/)
///   HUB_PERIPHERY_OUTPUT_FILENAME - hub periphery output file to write the deployed contract addresses to
///                                   (under script/deploy/outputs/hub-peripheries/)
contract DeployHubPeriphery is DeployPeriphery {
    address internal accessManager;
    address internal hubCoreRegistry;
    address internal sanctionsOracle;
    FlashloanProviders internal flProviders;

    HubPeriphery private _hubPeriphery;

    function deployment() public view returns (HubPeriphery memory) {
        return _hubPeriphery;
    }

    function _parseInputs() internal override {
        accessManager = vm.parseJsonAddress(inputJson, ".accessManager");
        hubCoreRegistry = vm.parseJsonAddress(inputJson, ".hubCoreRegistry");
        sanctionsOracle = vm.parseJsonAddress(inputJson, ".sanctionsOracle");
        flProviders = parseFlashloanProviders(inputJson, ".flashloanProviders");
    }

    function _peripherySetup() internal override {
        _hubPeriphery = deployHubPeriphery(accessManager, hubCoreRegistry, sanctionsOracle, flProviders);
    }

    function _writeOutput() internal override {
        string memory key = "key-deploy-hub-periphery-output-file";

        vm.serializeAddress(key, "FlashloanAggregator", address(_hubPeriphery.flashloanAggregator));
        vm.serializeAddress(key, "HubPeripheryRegistry", address(_hubPeriphery.hubPeripheryRegistry));
        vm.serializeAddress(key, "HubPeripheryFactory", address(_hubPeriphery.hubPeripheryFactory));
        vm.serializeAddress(key, "SecurityModuleBeacon", address(_hubPeriphery.securityModuleBeacon));
        vm.serializeAddress(key, "DirectDepositorBeacon", address(_hubPeriphery.directDepositorBeacon));
        vm.serializeAddress(key, "AsyncRedeemerBeacon", address(_hubPeriphery.asyncRedeemerBeacon));
        vm.serializeAddress(key, "AsyncRedeemerFeeBeacon", address(_hubPeriphery.asyncRedeemerFeeBeacon));
        vm.serializeAddress(key, "WatermarkFeeManagerBeacon", address(_hubPeriphery.watermarkFeeManagerBeacon));
        vm.serializeAddress(key, "MachineShareOracleBeacon", address(_hubPeriphery.machineShareOracleBeacon));
        vm.serializeAddress(key, "MachineShareOracleFactory", address(_hubPeriphery.machineShareOracleFactory));
        vm.writeJson(
            vm.serializeAddress(key, "MetaMorphoOracleFactory", address(_hubPeriphery.metaMorphoOracleFactory)),
            outputPath
        );
    }

    function _recordDir() internal pure override returns (string memory) {
        return "hub-peripheries";
    }

    function _loadFilenamesFromEnv() internal override {
        setFilenames(vm.envString("HUB_PERIPHERY_INPUT_FILENAME"), vm.envString("HUB_PERIPHERY_OUTPUT_FILENAME"));
    }
}
