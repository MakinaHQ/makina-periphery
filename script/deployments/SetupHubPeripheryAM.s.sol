// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {Script} from "forge-std/Script.sol";
import {stdJson} from "forge-std/StdJson.sol";

import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";

import {FlashloanAggregator} from "../../src/flashloans/FlashloanAggregator.sol";
import {HubPeripheryFactory} from "../../src/factories/HubPeripheryFactory.sol";
import {HubPeripheryRegistry} from "../../src/registries/HubPeripheryRegistry.sol";
import {MetaMorphoOracleFactory} from "../../src/factories/MetaMorphoOracleFactory.sol";

import {SortedParams} from "./utils/SortedParams.sol";

import {Base} from "../../test/base/Base.sol";

contract SetupHubPeripheryAM is Base, Script, SortedParams {
    using stdJson for string;

    string public deploymentInputJson;
    string public deploymentOutputJson;

    address private _accessManager;
    HubPeripherySorted private _hubPeriphery;

    constructor() {
        string memory deploymentInputFilename = vm.envString("HUB_INPUT_FILENAME");
        string memory deploymentOutputFilename = vm.envString("HUB_OUTPUT_FILENAME");

        string memory basePath = string.concat(vm.projectRoot(), "/script/deployments/");

        // load deployment input params
        string memory deploymentInputPath = string.concat(basePath, "inputs/hub-peripheries/");
        deploymentInputPath = string.concat(deploymentInputPath, deploymentInputFilename);
        deploymentInputJson = vm.readFile(deploymentInputPath);

        // load deployment output params
        string memory deploymentOutputPath = string.concat(basePath, "outputs/hub-peripheries/");
        deploymentOutputPath = string.concat(deploymentOutputPath, deploymentOutputFilename);
        deploymentOutputJson = vm.readFile(deploymentOutputPath);
    }

    function run() public {
        _accessManager = abi.decode(vm.parseJson(deploymentInputJson, ".accessManager"), (address));
        _hubPeriphery = abi.decode(vm.parseJson(deploymentOutputJson), (HubPeripherySorted));

        address sender = vm.envOr("TEST_SENDER", address(0));
        if (sender != address(0)) {
            vm.startBroadcast(sender);
        } else {
            vm.startBroadcast();
        }

        setupHubPeripheryAMFunctionRoles(
            _accessManager,
            HubPeriphery({
                flashloanAggregator: FlashloanAggregator(_hubPeriphery.flashloanAggregator),
                hubPeripheryRegistry: HubPeripheryRegistry(_hubPeriphery.hubPeripheryRegistry),
                hubPeripheryFactory: HubPeripheryFactory(_hubPeriphery.hubPeripheryFactory),
                directDepositorBeacon: UpgradeableBeacon(_hubPeriphery.directDepositorBeacon),
                asyncRedeemerBeacon: UpgradeableBeacon(_hubPeriphery.asyncRedeemerBeacon),
                watermarkFeeManagerBeacon: UpgradeableBeacon(_hubPeriphery.watermarkFeeManagerBeacon),
                securityModuleBeacon: UpgradeableBeacon(_hubPeriphery.securityModuleBeacon),
                metaMorphoOracleFactory: MetaMorphoOracleFactory(_hubPeriphery.metaMorphoOracleFactory)
            })
        );

        vm.stopBroadcast();
    }
}
