// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {stdJson} from "forge-std/StdJson.sol";

import {DeployPeriphery} from "./DeployPeriphery.s.sol";

contract DeployHubPeriphery is DeployPeriphery {
    using stdJson for string;

    address internal accessManager;
    address internal hubCoreRegistry;
    FlashloanProviders internal flProviders;

    HubPeriphery private _hubPeriphery;

    constructor() {
        string memory inputFilename = vm.envString("HUB_PERIPHERY_INPUT_FILENAME");
        string memory outputFilename = vm.envString("HUB_PERIPHERY_OUTPUT_FILENAME");

        string memory basePath = string.concat(vm.projectRoot(), "/script/deployments/");

        // load input params
        string memory inputPath = string.concat(basePath, "inputs/hub-peripheries/");
        inputPath = string.concat(inputPath, inputFilename);
        inputJson = vm.readFile(inputPath);

        // output path to later save deployed contracts
        outputPath = string.concat(basePath, "outputs/hub-peripheries/");
        outputPath = string.concat(outputPath, outputFilename);
    }

    function deployment() public view returns (HubPeriphery memory) {
        return _hubPeriphery;
    }

    function _deploySetupBefore() public override {
        accessManager = vm.parseJsonAddress(inputJson, ".accessManager");
        hubCoreRegistry = vm.parseJsonAddress(inputJson, ".hubCoreRegistry");
        flProviders = parseFlashloanProviders(inputJson, ".flashloanProviders");

        // start broadcasting transactions
        vm.startBroadcast();

        (, deployer,) = vm.readCallers();
    }

    function _coreSetup() public override {
        _hubPeriphery = deployHubPeriphery(accessManager, hubCoreRegistry, flProviders);
    }

    function _deploySetupAfter() public override {
        // finish broadcasting transactions
        vm.stopBroadcast();

        string memory key = "key-deploy-hub-periphery-output-file";

        // write to file
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
}
