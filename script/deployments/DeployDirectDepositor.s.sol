// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {Script} from "forge-std/Script.sol";
import {stdJson} from "forge-std/StdJson.sol";

import {IHubPeripheryFactory} from "../../src/interfaces/IHubPeripheryFactory.sol";

import {SortedParams} from "./utils/SortedParams.sol";

import {Base} from "../../test/base/Base.sol";

contract DeployDirectDepositor is Base, Script, SortedParams {
    using stdJson for string;

    string public deploymentOutputJson;
    string public implemIdsInputJson;
    string public inputJson;
    string public outputPath;

    HubPeripherySorted private _hubPeriphery;

    bool public whitelistStatus;

    address public deployedInstance;

    constructor() {
        string memory deploymentOutputFilename = vm.envString("HUB_OUTPUT_FILENAME");
        string memory implemIdsInputFilename = vm.envString("HUB_INPUT_FILENAME");
        string memory inputFilename = vm.envString("HUB_INPUT_FILENAME");
        string memory outputFilename = vm.envString("HUB_OUTPUT_FILENAME");

        string memory basePath = string.concat(vm.projectRoot(), "/script/deployments/");

        // load deployment output params
        string memory deploymentOutputPath = string.concat(basePath, "outputs/hub-peripheries/");
        deploymentOutputPath = string.concat(deploymentOutputPath, deploymentOutputFilename);
        deploymentOutputJson = vm.readFile(deploymentOutputPath);

        // load implem ids
        string memory inputPath = string.concat(basePath, "inputs/implem-ids/");
        inputPath = string.concat(inputPath, implemIdsInputFilename);
        implemIdsInputJson = vm.readFile(inputPath);

        // load input params
        inputPath = string.concat(basePath, "inputs/depositors/direct-depositors/");
        inputPath = string.concat(inputPath, inputFilename);
        inputJson = vm.readFile(inputPath);

        // output path to later save deployed contracts
        outputPath = string.concat(basePath, "outputs/depositors/direct-depositors/");
        outputPath = string.concat(outputPath, outputFilename);
    }

    function run() public {
        _hubPeriphery = abi.decode(vm.parseJson(deploymentOutputJson), (HubPeripherySorted));

        uint16 implemId = abi.decode(vm.parseJson(implemIdsInputJson, ".directDepositorImplemId"), (uint16));

        whitelistStatus = abi.decode(vm.parseJson(inputJson, ".whitelistStatus"), (bool));

        address sender = vm.envOr("TEST_SENDER", address(0));
        if (sender != address(0)) {
            vm.startBroadcast(sender);
        } else {
            vm.startBroadcast();
        }

        deployedInstance = IHubPeripheryFactory(_hubPeriphery.hubPeripheryFactory).createDepositor(
            implemId, abi.encode(whitelistStatus)
        );

        vm.stopBroadcast();

        string memory key = "key-deploy-direct-depositor-output-file";

        // write to file
        vm.writeJson(vm.serializeAddress(key, "DirectDepositor", deployedInstance), outputPath);
    }
}
