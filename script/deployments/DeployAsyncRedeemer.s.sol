// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {Script} from "forge-std/Script.sol";
import {stdJson} from "forge-std/StdJson.sol";

import {IHubPeripheryFactory} from "../../src/interfaces/IHubPeripheryFactory.sol";

import {Base} from "../../test/base/Base.sol";

contract DeployAsyncRedeemer is Base, Script {
    using stdJson for string;

    string public deploymentOutputJson;
    string public implemIdsInputJson;
    string public inputJson;
    string public outputPath;

    uint256 public finalizationDelay;
    uint256 public minRedeemAmount;
    bool public whitelistStatus;

    address public deployedInstance;

    constructor() {
        string memory deploymentOutputFilename = vm.envString("HUB_PERIPHERY_OUTPUT_FILENAME");
        string memory implemIdsInputFilename = vm.envString("HUB_PERIPHERY_INPUT_FILENAME");

        string memory inputFilename = vm.envString("HUB_STRAT_INPUT_FILENAME");
        string memory outputFilename = vm.envString("HUB_STRAT_OUTPUT_FILENAME");

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
        inputPath = string.concat(basePath, "inputs/redeemers/async-redeemers/");
        inputPath = string.concat(inputPath, inputFilename);
        inputJson = vm.readFile(inputPath);

        // output path to later save deployed contracts
        outputPath = string.concat(basePath, "outputs/redeemers/async-redeemers/");
        outputPath = string.concat(outputPath, outputFilename);
    }

    function run() public {
        uint16 implemId = uint16(vm.parseJsonUint(implemIdsInputJson, ".asyncRedeemerImplemId"));

        finalizationDelay = vm.parseJsonUint(inputJson, ".finalizationDelay");
        minRedeemAmount = vm.parseJsonUint(inputJson, ".minRedeemAmount");
        whitelistStatus = vm.parseJsonBool(inputJson, ".whitelistStatus");

        address sender = vm.envOr("TEST_SENDER", address(0));
        if (sender != address(0)) {
            vm.startBroadcast(sender);
        } else {
            vm.startBroadcast();
        }

        deployedInstance = IHubPeripheryFactory(vm.parseJsonAddress(deploymentOutputJson, ".HubPeripheryFactory"))
            .createRedeemer(implemId, abi.encode(finalizationDelay, minRedeemAmount, whitelistStatus));

        vm.stopBroadcast();

        string memory key = "key-deploy-async-redeemer-output-file";

        // write to file
        vm.writeJson(vm.serializeAddress(key, "AsyncRedeemer", deployedInstance), outputPath);
    }
}
