// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {Script} from "forge-std/Script.sol";
import {stdJson} from "forge-std/StdJson.sol";

import {IHubPeripheryFactory} from "../../src/interfaces/IHubPeripheryFactory.sol";
import {ISecurityModule} from "../../src/interfaces/ISecurityModule.sol";

import {Base} from "../../test/base/Base.sol";

contract DeploySecurityModule is Base, Script {
    using stdJson for string;

    string public deploymentOutputJson;
    string public inputJson;
    string public outputPath;

    address public deployedInstance;

    constructor() {
        string memory deploymentOutputFilename = vm.envString("HUB_PERIPHERY_OUTPUT_FILENAME");

        string memory inputFilename = vm.envString("HUB_STRAT_INPUT_FILENAME");
        string memory outputFilename = vm.envString("HUB_STRAT_OUTPUT_FILENAME");

        string memory basePath = string.concat(vm.projectRoot(), "/script/deployments/");

        // load deployment output params
        string memory deploymentOutputPath = string.concat(basePath, "outputs/hub-peripheries/");
        deploymentOutputPath = string.concat(deploymentOutputPath, deploymentOutputFilename);
        deploymentOutputJson = vm.readFile(deploymentOutputPath);

        // load input params
        string memory inputPath = string.concat(basePath, "inputs/security-modules/");
        inputPath = string.concat(inputPath, inputFilename);
        inputJson = vm.readFile(inputPath);

        // output path to later save deployed contracts
        outputPath = string.concat(basePath, "outputs/security-modules/");
        outputPath = string.concat(outputPath, outputFilename);
    }

    function run() public {
        ISecurityModule.SecurityModuleInitParams memory initParams = parseSecurityModuleInitParams(inputJson);

        address sender = vm.envOr("TEST_SENDER", address(0));
        if (sender != address(0)) {
            vm.startBroadcast(sender);
        } else {
            vm.startBroadcast();
        }

        deployedInstance = IHubPeripheryFactory(vm.parseJsonAddress(deploymentOutputJson, ".HubPeripheryFactory"))
            .createSecurityModule(initParams);

        vm.stopBroadcast();

        string memory key = "key-deploy-security-module-output-file";

        // write to file
        vm.writeJson(vm.serializeAddress(key, "SecurityModule", deployedInstance), outputPath);
    }
}
