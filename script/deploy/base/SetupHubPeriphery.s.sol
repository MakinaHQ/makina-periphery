// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {Script} from "forge-std/Script.sol";

import {Address} from "@openzeppelin/contracts/utils/Address.sol";

import {AMGovCalldata} from "@makina-core-script/deploy/utils/AMGovCalldata.sol";

import {Base} from "../../../test/base/Base.sol";

/// @notice Shared logic of the scripts wiring a hub periphery deployed by `DeployHubPeriphery`: the registry setters
///         and the AccessManager function roles.
/// @dev Every call is restricted on the hub AccessManager, so each list is one batch, submitted in order.
///
/// Modes, selected by the `VIEW_MODE` env var:
///   - Broadcast (default): sends the calls, from an account holding the required role.
///   - View (`VIEW_MODE=true`): logs each call's target and calldata, alongside its `AccessManager.schedule`
///     wrapper, sends nothing.
///
/// Env vars (unless `setFilenames` was called):
///   HUB_PERIPHERY_INPUT_FILENAME  - hub periphery input file holding the AccessManager address
///   HUB_PERIPHERY_OUTPUT_FILENAME - hub periphery output file holding the deployed contract addresses
///   VIEW_MODE (optional)          - true for view mode, unset or false for broadcast mode
abstract contract SetupHubPeriphery is Base, Script, AMGovCalldata {
    string public inputJson;
    string public outputJson;

    bool public viewMode;

    /// @dev In execution order.
    Call[] public calls;

    /// @dev Test hook to set the input and output filenames explicitly, instead of having `run` resolve them from
    ///      the env vars.
    function setFilenames(string memory inputFilename, string memory outputFilename) public {
        string memory basePath = string.concat(vm.projectRoot(), "/script/deploy/");

        inputJson = vm.readFile(string.concat(basePath, "inputs/hub-peripheries/", inputFilename));
        outputJson = vm.readFile(string.concat(basePath, "outputs/hub-peripheries/", outputFilename));
    }

    function setViewMode(bool _viewMode) public {
        viewMode = _viewMode;
    }

    /// @dev Reads `VIEW_MODE` and calls `setFilenames` with this script's env vars.
    function loadParamsFromEnv() public {
        viewMode = vm.envOr("VIEW_MODE", false);
        _loadFilenamesFromEnv();
    }

    function run() public {
        if (bytes(inputJson).length == 0) {
            loadParamsFromEnv();
        }

        _buildCalls();

        if (viewMode) {
            for (uint256 i; i < calls.length; ++i) {
                _logCall(calls[i]);
            }
            return;
        }

        vm.startBroadcast();

        for (uint256 i; i < calls.length; ++i) {
            Address.functionCall(calls[i].target, calls[i].data);
        }

        vm.stopBroadcast();
    }

    function callsLength() public view returns (uint256) {
        return calls.length;
    }

    /// @dev Pushes the calls, in execution order.
    function _buildCalls() internal virtual;

    /// @dev Calls `setFilenames` with this script's env vars.
    function _loadFilenamesFromEnv() internal virtual {
        setFilenames(vm.envString("HUB_PERIPHERY_INPUT_FILENAME"), vm.envString("HUB_PERIPHERY_OUTPUT_FILENAME"));
    }

    /// @dev An address of the hub periphery output file.
    function _deployed(string memory key) internal view returns (address) {
        return vm.parseJsonAddress(outputJson, string.concat(".", key));
    }

    function _pushCall(string memory label, address target, bytes memory data) internal {
        calls.push(Call({label: label, target: target, data: data}));
    }
}
