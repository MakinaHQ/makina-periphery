// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {Script} from "forge-std/Script.sol";
import {stdJson} from "forge-std/StdJson.sol";

import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";

import {FlashloanAggregator} from "../../src/flashloans/FlashloanAggregator.sol";
import {HubPeripheryFactory} from "../../src/factories/HubPeripheryFactory.sol";
import {HubPeripheryRegistry} from "../../src/registries/HubPeripheryRegistry.sol";
import {MachineShareOracleFactory} from "../../src/factories/MachineShareOracleFactory.sol";
import {MetaMorphoOracleFactory} from "../../src/factories/MetaMorphoOracleFactory.sol";

import {Base} from "../../test/base/Base.sol";

contract SetupHubPeripheryAM is Base, Script {
    using stdJson for string;

    string public deploymentInputJson;
    string public deploymentOutputJson;

    address private _accessManager;

    constructor() {
        string memory deploymentInputFilename = vm.envString("HUB_PERIPHERY_INPUT_FILENAME");
        string memory deploymentOutputFilename = vm.envString("HUB_PERIPHERY_OUTPUT_FILENAME");

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
        _accessManager = vm.parseJsonAddress(deploymentInputJson, ".accessManager");

        address sender = vm.envOr("TEST_SENDER", address(0));
        if (sender != address(0)) {
            vm.startBroadcast(sender);
        } else {
            vm.startBroadcast();
        }

        setupHubPeripheryAMFunctionRoles(
            _accessManager,
            HubPeriphery({
                flashloanAggregator: FlashloanAggregator(
                    vm.parseJsonAddress(deploymentOutputJson, ".FlashloanAggregator")
                ),
                hubPeripheryRegistry: HubPeripheryRegistry(
                    vm.parseJsonAddress(deploymentOutputJson, ".HubPeripheryRegistry")
                ),
                hubPeripheryFactory: HubPeripheryFactory(
                    vm.parseJsonAddress(deploymentOutputJson, ".HubPeripheryFactory")
                ),
                directDepositorBeacon: UpgradeableBeacon(
                    vm.parseJsonAddress(deploymentOutputJson, ".DirectDepositorBeacon")
                ),
                asyncRedeemerBeacon: UpgradeableBeacon(
                    vm.parseJsonAddress(deploymentOutputJson, ".AsyncRedeemerBeacon")
                ),
                asyncRedeemerFeeBeacon: UpgradeableBeacon(
                    vm.parseJsonAddress(deploymentOutputJson, ".AsyncRedeemerFeeBeacon")
                ),
                watermarkFeeManagerBeacon: UpgradeableBeacon(
                    vm.parseJsonAddress(deploymentOutputJson, ".WatermarkFeeManagerBeacon")
                ),
                securityModuleBeacon: UpgradeableBeacon(
                    vm.parseJsonAddress(deploymentOutputJson, ".SecurityModuleBeacon")
                ),
                metaMorphoOracleFactory: MetaMorphoOracleFactory(
                    vm.parseJsonAddress(deploymentOutputJson, ".MetaMorphoOracleFactory")
                ),
                machineShareOracleBeacon: UpgradeableBeacon(
                    vm.parseJsonAddress(deploymentOutputJson, ".MachineShareOracleBeacon")
                ),
                machineShareOracleFactory: MachineShareOracleFactory(
                    vm.parseJsonAddress(deploymentOutputJson, ".MachineShareOracleFactory")
                )
            })
        );

        vm.stopBroadcast();
    }
}
