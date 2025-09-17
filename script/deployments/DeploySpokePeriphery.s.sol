// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {stdJson} from "forge-std/StdJson.sol";

import {FlashloanAggregator} from "../../src/flashloans/FlashloanAggregator.sol";

import {DeployPeriphery} from "./DeployPeriphery.s.sol";

contract DeploySpokePeriphery is DeployPeriphery {
    using stdJson for string;

    address public caliberFactory;
    FlashloanProvidersSorted public flProviders;

    FlashloanAggregator private deployedInstance;

    constructor() {
        string memory inputFilename = vm.envString("SPOKE_INPUT_FILENAME");
        string memory outputFilename = vm.envString("SPOKE_OUTPUT_FILENAME");

        string memory basePath = string.concat(vm.projectRoot(), "/script/deployments/");

        // load input params
        string memory inputPath = string.concat(basePath, "inputs/spoke-peripheries/");
        inputPath = string.concat(inputPath, inputFilename);
        inputJson = vm.readFile(inputPath);

        // output path to later save deployed contracts
        outputPath = string.concat(basePath, "outputs/spoke-peripheries/");
        outputPath = string.concat(outputPath, outputFilename);
    }

    function deployment() public view returns (FlashloanAggregator) {
        return deployedInstance;
    }

    function _deploySetupBefore() public override {
        caliberFactory = abi.decode(vm.parseJson(inputJson, ".caliberFactory"), (address));
        flProviders = abi.decode(vm.parseJson(inputJson, ".flashloanProviders"), (FlashloanProvidersSorted));

        // start broadcasting transactions
        vm.startBroadcast();

        (, deployer,) = vm.readCallers();
    }

    function _coreSetup() public override {
        deployedInstance = deployFlashloanAggregator(
            caliberFactory,
            FlashloanProviders({
                balancerV2Pool: flProviders.balancerV2Pool,
                balancerV3Pool: flProviders.balancerV3Pool,
                morphoPool: flProviders.morphoPool,
                dssFlash: flProviders.dssFlash,
                aaveV3AddressProvider: flProviders.aaveV3AddressProvider,
                dai: flProviders.dai
            })
        );
    }

    function _deploySetupAfter() public override {
        vm.stopBroadcast();

        // Write to file
        string memory key = "key-deploy-spoke-periphery-output-file";
        vm.writeJson(vm.serializeAddress(key, "FlashloanAggregator", address(deployedInstance)), outputPath);
    }
}
