// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {Script} from "forge-std/Script.sol";
import {stdJson} from "forge-std/StdJson.sol";

import {SortedParams} from "./utils/SortedParams.sol";

import {Base} from "../../test/base/Base.sol";

contract SetupHubPeripheryRegistry is Base, Script, SortedParams {
    using stdJson for string;

    string public deploymentInputJson;
    string public deploymentOutputJson;
    string public inputJson;

    address private _accessManager;
    HubPeripherySorted private _hubPeriphery;

    uint16[] private mdImplemIds;
    uint16[] private mrImplemIds;
    uint16[] private fmImplemIds;

    address[] private mdBeacons;
    address[] private mrBeacons;
    address[] private fmBeacons;

    constructor() {
        string memory deploymentInputFilename = vm.envString("HUB_INPUT_FILENAME");
        string memory deploymentOutputFilename = vm.envString("HUB_OUTPUT_FILENAME");
        string memory inputFilename = vm.envString("HUB_INPUT_FILENAME");

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
        _accessManager = abi.decode(vm.parseJson(deploymentInputJson, ".accessManager"), (address));
        _hubPeriphery = abi.decode(vm.parseJson(deploymentOutputJson), (HubPeripherySorted));

        mdImplemIds = new uint16[](1);
        mdImplemIds[0] = abi.decode(vm.parseJson(inputJson, ".directDepositorImplemId"), (uint16));
        mdBeacons = new address[](1);
        mdBeacons[0] = _hubPeriphery.directDepositorBeacon;

        mrImplemIds = new uint16[](1);
        mrImplemIds[0] = abi.decode(vm.parseJson(inputJson, ".asyncRedeemerImplemId"), (uint16));
        mrBeacons = new address[](1);
        mrBeacons[0] = _hubPeriphery.asyncRedeemerBeacon;

        fmImplemIds = new uint16[](1);
        fmImplemIds[0] = abi.decode(vm.parseJson(inputJson, ".watermarkFeeManagerImplemId"), (uint16));
        fmBeacons = new address[](1);
        fmBeacons[0] = _hubPeriphery.watermarkFeeManagerBeacon;

        address sender = vm.envOr("TEST_SENDER", address(0));
        if (sender != address(0)) {
            vm.startBroadcast(sender);
        } else {
            vm.startBroadcast();
        }

        registerHubPeripheryFactory(_hubPeriphery.hubPeripheryRegistry, _hubPeriphery.hubPeripheryFactory);
        registerSecurityModuleBeacon(_hubPeriphery.hubPeripheryRegistry, _hubPeriphery.securityModuleBeacon);
        registerDepositorBeacons(_hubPeriphery.hubPeripheryRegistry, mdImplemIds, mdBeacons);
        registerRedeemerBeacons(_hubPeriphery.hubPeripheryRegistry, mrImplemIds, mrBeacons);
        registerFeeManagerBeacons(_hubPeriphery.hubPeripheryRegistry, fmImplemIds, fmBeacons);

        vm.stopBroadcast();
    }
}
