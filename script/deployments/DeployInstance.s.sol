// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {Script} from "forge-std/Script.sol";

import {Address} from "@openzeppelin/contracts/utils/Address.sol";

import {AMGovCalldata} from "@makina-core-script/deploy/utils/AMGovCalldata.sol";

import {Base} from "../../test/base/Base.sol";

/// @notice Shared logic of the scripts creating machine periphery components (security module, depositor, redeemer,
///         fee manager) through the HubPeripheryFactory.
/// @dev The factory `create*` functions are restricted: broadcast from an account holding the
///      STRATEGY_DEPLOYMENT_ROLE, or run in view mode to log the calldata for that account to submit.
///
/// Modes, selected by the `VIEW_MODE` env var:
///   - Broadcast (default): sends the call and writes the deployed address to the output file.
///   - View (`VIEW_MODE=true`): logs the factory address and the calldata, alongside its `AccessManager.schedule`
///     wrapper, sends nothing and writes no file.
///
/// Env vars (read by the concrete scripts, unless `setParams` was called):
///   HUB_PERIPHERY_OUTPUT_FILENAME - hub periphery output file holding the HubPeripheryFactory address
///   HUB_PERIPHERY_INPUT_FILENAME  - implementation ids input file, for the components created from a beacon
///   HUB_STRAT_INPUT_FILENAME      - component init params input file
///   HUB_STRAT_OUTPUT_FILENAME     - file to write the deployed address to (broadcast mode only)
///   VIEW_MODE (optional)          - true for view mode, unset or false for broadcast mode
abstract contract DeployInstance is Base, Script, AMGovCalldata {
    string public inputJson;
    string public outputPath;

    address public peripheryFactory;

    /// @dev Unused by the components created without implementation id (security module).
    uint16 public implemId;

    bool public viewMode;

    address public deployedInstance;

    /// @dev Test hook to set the periphery factory and the input/output filenames explicitly, instead of having `run`
    ///      resolve them from the env vars and the hub periphery output file. An empty output filename skips writing
    ///      the output file.
    function setParams(address _peripheryFactory, string memory inputFilename, string memory outputFilename) public {
        peripheryFactory = _peripheryFactory;

        string memory basePath = string.concat(vm.projectRoot(), "/script/deployments/");

        inputJson = vm.readFile(string.concat(basePath, "inputs/", _recordDir(), "/", inputFilename));

        outputPath = bytes(outputFilename).length == 0
            ? ""
            : string.concat(basePath, "outputs/", _recordDir(), "/", outputFilename);
    }

    /// @dev Test hook to set the implementation id explicitly, instead of having `run` resolve it from the
    ///      implementation ids input file.
    function setImplemId(uint16 _implemId) public {
        implemId = _implemId;
    }

    function setViewMode(bool _viewMode) public {
        viewMode = _viewMode;
    }

    /// @dev Reads `VIEW_MODE` and calls `setParams` with this script's env vars.
    function loadParamsFromEnv() public {
        viewMode = vm.envOr("VIEW_MODE", false);
        _loadParamsFromEnv();
    }

    function run() public {
        if (bytes(inputJson).length == 0) {
            loadParamsFromEnv();
        }

        Call memory call = _createCall();

        if (viewMode) {
            _logCall(call);
            _logPostCreate();
            return;
        }

        vm.startBroadcast();

        deployedInstance = abi.decode(Address.functionCall(call.target, call.data), (address));

        _postCreate();

        vm.stopBroadcast();

        if (bytes(outputPath).length != 0) {
            _writeOutput();
        }
    }

    /// @dev The periphery factory call creating the component, built from the input file.
    function _createCall() internal view virtual returns (Call memory);

    function _writeOutput() internal virtual;

    /// @dev Directory name of this script's input and output records, under `inputs/` and `outputs/`.
    function _recordDir() internal pure virtual returns (string memory);

    /// @dev Calls `setParams` with this script's env vars, `viewMode` being already set.
    function _loadParamsFromEnv() internal virtual;

    /// @dev Follow-up calls on the created component, broadcast mode only. Nothing by default.
    function _postCreate() internal virtual {}

    /// @dev View mode counterpart of `_postCreate`, logging what remains to be submitted. Nothing by default.
    function _logPostCreate() internal view virtual {}

    /// @dev HubPeripheryFactory address read from a hub periphery output record.
    function _peripheryFactoryFromRecord(string memory outputFilename) internal view returns (address) {
        string memory recordPath =
            string.concat(vm.projectRoot(), "/script/deployments/outputs/hub-peripheries/", outputFilename);
        return vm.parseJsonAddress(vm.readFile(recordPath), ".HubPeripheryFactory");
    }

    /// @dev Implementation id read from an implementation ids input record.
    function _implemIdFromRecord(string memory inputFilename, string memory key) internal view returns (uint16) {
        string memory recordPath =
            string.concat(vm.projectRoot(), "/script/deployments/inputs/implem-ids/", inputFilename);
        return uint16(vm.parseJsonUint(vm.readFile(recordPath), key));
    }

    /// @dev The output filename is not needed in view mode, as no file is written.
    function _outputFilenameFromEnv(string memory envVar) internal view returns (string memory) {
        return viewMode ? "" : vm.envString(envVar);
    }
}
