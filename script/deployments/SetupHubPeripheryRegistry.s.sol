// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {Script} from "forge-std/Script.sol";
import {stdJson} from "forge-std/StdJson.sol";

import {Base} from "../../test/base/Base.sol";

contract SetupHubPeripheryRegistry is Base, Script {
    using stdJson for string;

    string public deploymentInputJson;
    string public deploymentOutputJson;
    string public inputJson;

    address private _accessManager;

    uint16[] private mdImplemIds;
    uint16[] private mrImplemIds;
    uint16[] private fmImplemIds;

    address[] private mdBeacons;
    address[] private mrBeacons;
    address[] private fmBeacons;

    constructor() {
        string memory deploymentInputFilename = vm.envString("HUB_PERIPHERY_INPUT_FILENAME");
        string memory deploymentOutputFilename = vm.envString("HUB_PERIPHERY_OUTPUT_FILENAME");

        string memory inputFilename = vm.envString("HUB_STRAT_INPUT_FILENAME");

        string memory basePath = string.concat(vm.projectRoot(), "/script/deployments/");

        // load deployment input params
        string memory deploymentInputPath = string.concat(basePath, "inputs/hub-peripheries/");
        deploymentInputPath = string.concat(deploymentInputPath, deploymentInputFilename);
        deploymentInputJson = vm.readFile(deploymentInputPath);

        // load deployment output params
        string memory deploymentOutputPath = string.concat(basePath, "outputs/hub-peripheries/");
        deploymentOutputPath = string.concat(deploymentOutputPath, deploymentOutputFilename);
        deploymentOutputJson = vm.readFile(deploymentOutputPath);

        // load implem ids
        string memory inputPath = string.concat(basePath, "inputs/implem-ids/");
        inputPath = string.concat(inputPath, inputFilename);
        inputJson = vm.readFile(inputPath);
    }

    function run() public {
        _accessManager = vm.parseJsonAddress(deploymentInputJson, ".accessManager");

        mdImplemIds = new uint16[](1);
        mdImplemIds[0] = uint16(vm.parseJsonUint(inputJson, ".directDepositorImplemId"));
        mdBeacons = new address[](1);
        mdBeacons[0] = vm.parseJsonAddress(deploymentOutputJson, ".DirectDepositorBeacon");

        mrImplemIds = new uint16[](2);
        mrImplemIds[0] = uint16(vm.parseJsonUint(inputJson, ".asyncRedeemerImplemId"));
        mrImplemIds[1] = uint16(vm.parseJsonUint(inputJson, ".asyncRedeemerFeeImplemId"));
        mrBeacons = new address[](2);
        mrBeacons[0] = vm.parseJsonAddress(deploymentOutputJson, ".AsyncRedeemerBeacon");
        mrBeacons[1] = vm.parseJsonAddress(deploymentOutputJson, ".AsyncRedeemerFeeBeacon");

        fmImplemIds = new uint16[](1);
        fmImplemIds[0] = uint16(vm.parseJsonUint(inputJson, ".watermarkFeeManagerImplemId"));
        fmBeacons = new address[](1);
        fmBeacons[0] = vm.parseJsonAddress(deploymentOutputJson, ".WatermarkFeeManagerBeacon");

        address sender = vm.envOr("TEST_SENDER", address(0));
        if (sender != address(0)) {
            vm.startBroadcast(sender);
        } else {
            vm.startBroadcast();
        }

        address hubPeripheryRegistry = vm.parseJsonAddress(deploymentOutputJson, ".HubPeripheryRegistry");

        registerHubPeripheryFactory(
            hubPeripheryRegistry, vm.parseJsonAddress(deploymentOutputJson, ".HubPeripheryFactory")
        );
        registerSecurityModuleBeacon(
            hubPeripheryRegistry, vm.parseJsonAddress(deploymentOutputJson, ".SecurityModuleBeacon")
        );
        registerDepositorBeacons(hubPeripheryRegistry, mdImplemIds, mdBeacons);
        registerRedeemerBeacons(hubPeripheryRegistry, mrImplemIds, mrBeacons);
        registerFeeManagerBeacons(hubPeripheryRegistry, fmImplemIds, fmBeacons);

        vm.stopBroadcast();
    }
}
