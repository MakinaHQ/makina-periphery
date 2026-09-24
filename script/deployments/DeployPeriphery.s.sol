// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

// solhint-disable gas-custom-errors, reason-string

import {Script} from "forge-std/Script.sol";

import {CreateXUtils} from "@makina-core-script/deploy/utils/CreateXUtils.sol";

import {Base} from "../../test/base/Base.sol";

/// @notice Shared logic of the scripts deploying the periphery shared contracts of a chain (hub or spoke).
/// @dev Deployments go through CreateX and are bound to the broadcasting address, see `_deployCode`.
///
/// Env vars (read by the concrete scripts, unless `setFilenames` was called):
///   <HUB|SPOKE>_PERIPHERY_INPUT_FILENAME  - periphery input file holding the deployment parameters
///   <HUB|SPOKE>_PERIPHERY_OUTPUT_FILENAME - periphery output file to write the deployed contract addresses to
abstract contract DeployPeriphery is Base, Script, CreateXUtils {
    string public inputJson;
    string public outputPath;

    address public deployer;

    /// @dev Test hook to set the input and output filenames explicitly, instead of having `run` resolve them from
    ///      the env vars. An empty output filename skips writing the output file.
    function setFilenames(string memory inputFilename, string memory outputFilename) public {
        string memory basePath = string.concat(vm.projectRoot(), "/script/deployments/");

        inputJson = vm.readFile(string.concat(basePath, "inputs/", _recordDir(), "/", inputFilename));

        outputPath = bytes(outputFilename).length == 0
            ? ""
            : string.concat(basePath, "outputs/", _recordDir(), "/", outputFilename);
    }

    /// @dev Calls `setFilenames` with this script's env vars.
    function loadParamsFromEnv() public {
        _loadFilenamesFromEnv();
    }

    function run() public {
        if (bytes(inputJson).length == 0) {
            loadParamsFromEnv();
        }

        _parseInputs();

        vm.startBroadcast();

        (, deployer,) = vm.readCallers();

        _peripherySetup();

        vm.stopBroadcast();

        if (bytes(outputPath).length != 0) {
            _writeOutput();
        }
    }

    function _parseInputs() internal virtual;

    function _peripherySetup() internal virtual;

    function _writeOutput() internal virtual;

    /// @dev Directory name of this script's input and output records, under `inputs/` and `outputs/`.
    function _recordDir() internal pure virtual returns (string memory);

    /// @dev Calls `setFilenames` with this script's env vars.
    function _loadFilenamesFromEnv() internal virtual;

    /// @dev Deploys through CreateX at the deployer-bound address and asserts it. An occupied CREATE2 slot (zero salt
    ///      domain, used for implementations) is reused: that address is bound to the init code hash, so the code
    ///      there is this exact bytecode. An occupied CREATE3 slot reverts before broadcasting, with a readable error
    ///      instead of CreateX's opaque one.
    function _deployCode(bytes memory bytecode, bytes32 salt) internal virtual override returns (address deployed) {
        deployed = _computeCreateXAddress(bytecode, salt, deployer);

        if (deployed.code.length != 0) {
            if (salt == 0) {
                return deployed;
            }
            revert(string.concat("DeployPeriphery: CREATE3 target already has code: ", vm.toString(deployed)));
        }

        require(_deployCodeCreateX(bytecode, salt, deployer) == deployed, "DeployPeriphery: CreateX address mismatch");
    }
}
