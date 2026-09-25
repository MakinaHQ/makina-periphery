// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {FlashloanAggregator} from "../../src/flashloans/FlashloanAggregator.sol";

import {DeployPeriphery} from "./base/DeployPeriphery.s.sol";

/// @notice Deploys the Makina spoke periphery: a FlashloanAggregator bound to the caliber factory of the spoke core
///         named in the input file.
/// @dev The aggregator is deployed at an address discriminated by the hub chain id of the spoke's instance, read from
///      the spoke core, which must be wired beforehand. See `Base.deploySpokePeriphery`.
///
/// Env vars (unless `setFilenames` was called):
///   SPOKE_PERIPHERY_INPUT_FILENAME  - spoke periphery input file holding the deployment parameters
///                                     (under script/deploy/inputs/spoke-peripheries/)
///   SPOKE_PERIPHERY_OUTPUT_FILENAME - spoke periphery output file to write the deployed contract address to
///                                     (under script/deploy/outputs/spoke-peripheries/)
contract DeploySpokePeriphery is DeployPeriphery {
    address internal spokeCoreRegistry;
    FlashloanProviders internal flProviders;

    FlashloanAggregator private _flashloanAggregator;

    function deployment() public view returns (FlashloanAggregator) {
        return _flashloanAggregator;
    }

    function _parseInputs() internal override {
        spokeCoreRegistry = vm.parseJsonAddress(inputJson, ".spokeCoreRegistry");
        flProviders = parseFlashloanProviders(inputJson, ".flashloanProviders");
    }

    function _peripherySetup() internal override {
        _flashloanAggregator = deploySpokePeriphery(spokeCoreRegistry, flProviders);
    }

    function _writeOutput() internal override {
        string memory key = "key-deploy-spoke-periphery-output-file";
        vm.writeJson(vm.serializeAddress(key, "FlashloanAggregator", address(_flashloanAggregator)), outputPath);
    }

    function _recordDir() internal pure override returns (string memory) {
        return "spoke-peripheries";
    }

    function _loadFilenamesFromEnv() internal override {
        setFilenames(vm.envString("SPOKE_PERIPHERY_INPUT_FILENAME"), vm.envString("SPOKE_PERIPHERY_OUTPUT_FILENAME"));
    }
}
