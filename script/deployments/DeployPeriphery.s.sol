// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {Script} from "forge-std/Script.sol";
import {stdJson} from "forge-std/StdJson.sol";

import {CreateXUtils} from "@makina-core-script/deployments/utils/CreateXUtils.sol";

import {FlashloanAggregator} from "../../src/flashloans/FlashloanAggregator.sol";

import {SortedParams} from "./utils/SortedParams.sol";

import {Base} from "../../test/base/Base.sol";

contract DeployPeriphery is Base, Script, SortedParams, CreateXUtils {
    using stdJson for string;

    string public inputJson;
    string public outputPath;

    address public deployer;

    function run() public {
        _deploySetupBefore();
        _coreSetup();
        _deploySetupAfter();
    }

    function deployFlashloanAggregator(address _caliberFactory, FlashloanProviders memory _flProviders)
        public
        override
        returns (FlashloanAggregator)
    {
        return FlashloanAggregator(
            _deployCodeCreateX(
                abi.encodePacked(type(FlashloanAggregator).creationCode, abi.encode(_caliberFactory, _flProviders)),
                bytes32(0),
                deployer
            )
        );
    }

    function _coreSetup() public virtual {}

    function _deploySetupBefore() public virtual {}

    function _deploySetupAfter() public virtual {}
}
