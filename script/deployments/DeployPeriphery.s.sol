// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {Script} from "forge-std/Script.sol";
import {stdJson} from "forge-std/StdJson.sol";

import {CreateXUtils} from "@makina-core-script/deployments/utils/CreateXUtils.sol";

import {FlashloanAggregator} from "../../src/flashloans/FlashloanAggregator.sol";

import {Base} from "../../test/base/Base.sol";

contract DeployPeriphery is Base, Script, CreateXUtils {
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
        internal
        override
        returns (FlashloanAggregator)
    {
        bytes32 salt;
        if (vm.envOr("TEST_ENV", false)) {
            salt = keccak256("TestFlashloanAggregator");
        }
        return FlashloanAggregator(
            _deployCodeCreateX(
                abi.encodePacked(
                    type(FlashloanAggregator).creationCode,
                    abi.encode(
                        _caliberFactory,
                        _flProviders.balancerV2Pool,
                        _flProviders.balancerV3Pool,
                        _flProviders.morphoPool,
                        _flProviders.dssFlash,
                        _flProviders.aaveV3AddressProvider,
                        _flProviders.dai
                    )
                ),
                salt,
                deployer
            )
        );
    }

    function _coreSetup() public virtual {}

    function _deploySetupBefore() public virtual {}

    function _deploySetupAfter() public virtual {}
}
