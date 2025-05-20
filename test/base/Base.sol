// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.28;

import {ICoreRegistry} from "@makina-core/interfaces/ICoreRegistry.sol";

import {FlashloanAggregator} from "../../src/flashloans/FlashloanAggregator.sol";

abstract contract Base {
    struct Periphery {
        FlashloanAggregator flashloanAggregator;
    }

    struct FlashloanProviders {
        address _balancerV2Pool;
        address _balancerV3Pool;
        address _morphoPool;
        address _dssFlash;
        address _aaveV3AddressProvider;
        address _dai;
    }

    ///
    /// PERIPHERY DEPLOYMENTS
    ///

    function deployPeriphery(address coreFactory, FlashloanProviders memory flProviders)
        public
        returns (Periphery memory deployment)
    {
        deployment.flashloanAggregator = new FlashloanAggregator(
            coreFactory,
            flProviders._balancerV2Pool,
            flProviders._balancerV3Pool,
            flProviders._morphoPool,
            flProviders._dssFlash,
            flProviders._aaveV3AddressProvider,
            flProviders._dai
        );
    }

    ///
    /// REGISTRIES SETUP
    ///

    function setupCoreRegistry(address coreRegistry, Periphery memory deployment) public {
        ICoreRegistry(coreRegistry).setFlashLoanModule(address(deployment.flashloanAggregator));
    }
}
