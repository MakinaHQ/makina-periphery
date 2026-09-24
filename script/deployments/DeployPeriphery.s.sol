// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

// solhint-disable gas-custom-errors, reason-string

import {Script} from "forge-std/Script.sol";
import {stdJson} from "forge-std/StdJson.sol";

import {CreateXUtils} from "@makina-core-script/deploy/utils/CreateXUtils.sol";

import {Base} from "../../test/base/Base.sol";

abstract contract DeployPeriphery is Base, Script, CreateXUtils {
    using stdJson for string;

    string public inputJson;
    string public outputPath;

    address public deployer;

    function run() public {
        _deploySetupBefore();
        _coreSetup();
        _deploySetupAfter();
    }

    function _coreSetup() internal virtual {}

    function _deploySetupBefore() internal virtual {}

    function _deploySetupAfter() internal virtual {}

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
