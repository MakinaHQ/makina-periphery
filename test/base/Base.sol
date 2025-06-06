// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.28;

import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import {ICoreRegistry} from "@makina-core/interfaces/ICoreRegistry.sol";
import {IHubPeripheryRegistry} from "../../src/interfaces/IHubPeripheryRegistry.sol";

import {FlashloanAggregator} from "../../src/flashloans/FlashloanAggregator.sol";
import {HubPeripheryRegistry} from "../../src/registries/HubPeripheryRegistry.sol";
import {HubPeripheryFactory} from "../../src/factories/HubPeripheryFactory.sol";

abstract contract Base {
    struct HubPeriphery {
        FlashloanAggregator flashloanAggregator;
        HubPeripheryRegistry hubPeripheryRegistry;
        HubPeripheryFactory hubPeripheryFactory;
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
    /// HUB PERIPHERY DEPLOYMENTS
    ///

    function deployPeriphery(
        address accessManager,
        address coreFactory,
        address dao,
        FlashloanProviders memory flProviders
    ) public returns (HubPeriphery memory deployment) {
        deployment.flashloanAggregator = new FlashloanAggregator(
            coreFactory,
            flProviders._balancerV2Pool,
            flProviders._balancerV3Pool,
            flProviders._morphoPool,
            flProviders._dssFlash,
            flProviders._aaveV3AddressProvider,
            flProviders._dai
        );

        address hubPeripheryRegistryImplemAddr = address(new HubPeripheryRegistry());
        deployment.hubPeripheryRegistry = HubPeripheryRegistry(
            address(
                new TransparentUpgradeableProxy(
                    hubPeripheryRegistryImplemAddr,
                    dao,
                    abi.encodeCall(HubPeripheryRegistry.initialize, (address(accessManager)))
                )
            )
        );

        address hubPeripheryFactoryImplemAddr =
            address(new HubPeripheryFactory(address(deployment.hubPeripheryRegistry)));
        deployment.hubPeripheryFactory = HubPeripheryFactory(
            address(
                new TransparentUpgradeableProxy(
                    hubPeripheryFactoryImplemAddr,
                    dao,
                    abi.encodeCall(HubPeripheryFactory.initialize, (address(accessManager)))
                )
            )
        );
    }

    ///
    /// REGISTRIES SETUP
    ///

    function registerFlashloanAggregator(address coreRegistry, address flashloanAggregator) public {
        ICoreRegistry(coreRegistry).setFlashLoanModule(flashloanAggregator);
    }

    function registerHubPeripheryFactory(address hubPeripheryRegistry, address hubPeripheryFactory) public {
        IHubPeripheryRegistry(hubPeripheryRegistry).setPeripheryFactory(hubPeripheryFactory);
    }

    function registerDepositManagerBeacons(
        address hubPeripheryRegistry,
        uint16[] memory implemIds,
        address[] memory depositManagerBeacons
    ) public {
        require(implemIds.length == depositManagerBeacons.length, "Mismatched lengths");

        for (uint256 i; i < implemIds.length; ++i) {
            IHubPeripheryRegistry(hubPeripheryRegistry).setDepositManagerBeacon(implemIds[i], depositManagerBeacons[i]);
        }
    }

    function registerRedeemManagerBeacons(
        address hubPeripheryRegistry,
        uint16[] memory implemIds,
        address[] memory redeemManagerBeacons
    ) public {
        require(implemIds.length == redeemManagerBeacons.length, "Mismatched lengths");

        for (uint256 i; i < implemIds.length; ++i) {
            IHubPeripheryRegistry(hubPeripheryRegistry).setRedeemManagerBeacon(implemIds[i], redeemManagerBeacons[i]);
        }
    }

    function registerFeeManagerBeacons(
        address hubPeripheryRegistry,
        uint16[] memory implemIds,
        address[] memory feeManagerBeacons
    ) public {
        require(implemIds.length == feeManagerBeacons.length, "Mismatched lengths");

        for (uint256 i; i < implemIds.length; ++i) {
            IHubPeripheryRegistry(hubPeripheryRegistry).setFeeManagerBeacon(implemIds[i], feeManagerBeacons[i]);
        }
    }
}
