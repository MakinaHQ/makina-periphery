// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.28;

import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";

import {ICoreRegistry} from "@makina-core/interfaces/ICoreRegistry.sol";
import {IHubPeripheryRegistry} from "../../src/interfaces/IHubPeripheryRegistry.sol";

import {FlashloanAggregator} from "../../src/flashloans/FlashloanAggregator.sol";
import {HubPeripheryRegistry} from "../../src/registries/HubPeripheryRegistry.sol";
import {HubPeripheryFactory} from "../../src/factories/HubPeripheryFactory.sol";
import {WatermarkFeeManager} from "../../src/fee-managers/WatermarkFeeManager.sol";
import {DirectDepositor} from "../../src/depositors/DirectDepositor.sol";
import {AsyncRedeemer} from "../../src/redeemers/AsyncRedeemer.sol";
import {SecurityModule} from "../../src/security-module/SecurityModule.sol";
import {MetaMorphoOracleFactory} from "../../src/factories/MetaMorphoOracleFactory.sol";

abstract contract Base {
    struct HubPeriphery {
        FlashloanAggregator flashloanAggregator;
        HubPeripheryRegistry hubPeripheryRegistry;
        HubPeripheryFactory hubPeripheryFactory;
        UpgradeableBeacon directDepositorBeacon;
        UpgradeableBeacon asyncRedeemerBeacon;
        UpgradeableBeacon watermarkFeeManagerBeacon;
        UpgradeableBeacon securityModuleBeacon;
        MetaMorphoOracleFactory metaMorphoOracleFactory;
    }

    struct FlashloanProviders {
        address balancerV2Pool;
        address balancerV3Pool;
        address morphoPool;
        address dssFlash;
        address aaveV3AddressProvider;
        address dai;
    }

    ///
    /// HUB PERIPHERY DEPLOYMENTS
    ///

    function deployHubPeriphery(
        address accessManager,
        address caliberFactory,
        FlashloanProviders memory flProviders,
        address dao
    ) public returns (HubPeriphery memory deployment) {
        deployment.flashloanAggregator = deployFlashloanAggregator(caliberFactory, flProviders);

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
        address directDepositorImplemAddr = address(new DirectDepositor(address(deployment.hubPeripheryRegistry)));
        deployment.directDepositorBeacon = new UpgradeableBeacon(directDepositorImplemAddr, dao);

        address asyncRedeemerImplemAddr = address(new AsyncRedeemer(address(deployment.hubPeripheryRegistry)));
        deployment.asyncRedeemerBeacon = new UpgradeableBeacon(asyncRedeemerImplemAddr, dao);

        address watermarkFeeManagerImplemAddr =
            address(new WatermarkFeeManager(address(deployment.hubPeripheryRegistry)));
        deployment.watermarkFeeManagerBeacon = new UpgradeableBeacon(watermarkFeeManagerImplemAddr, dao);

        address securityModuleImplemAddr = address(new SecurityModule(address(deployment.hubPeripheryRegistry)));
        deployment.securityModuleBeacon = new UpgradeableBeacon(securityModuleImplemAddr, dao);

        address metaMorphoOracleFactoryImplemAddr = address(new MetaMorphoOracleFactory());
        deployment.metaMorphoOracleFactory = MetaMorphoOracleFactory(
            address(
                new TransparentUpgradeableProxy(
                    metaMorphoOracleFactoryImplemAddr,
                    dao,
                    abi.encodeCall(MetaMorphoOracleFactory.initialize, (address(accessManager)))
                )
            )
        );
    }

    function deployFlashloanAggregator(address caliberFactory, FlashloanProviders memory flProviders)
        public
        returns (FlashloanAggregator)
    {
        return new FlashloanAggregator(
            caliberFactory,
            flProviders.balancerV2Pool,
            flProviders.balancerV3Pool,
            flProviders.morphoPool,
            flProviders.dssFlash,
            flProviders.aaveV3AddressProvider,
            flProviders.dai
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

    function registerSecurityModuleBeacon(address hubPeripheryRegistry, address securityModuleBeacon) public {
        IHubPeripheryRegistry(hubPeripheryRegistry).setSecurityModuleBeacon(securityModuleBeacon);
    }

    function registerDepositorBeacons(
        address hubPeripheryRegistry,
        uint16[] memory implemIds,
        address[] memory depositorBeacons
    ) public {
        require(implemIds.length == depositorBeacons.length, "Mismatched lengths");

        for (uint256 i; i < implemIds.length; ++i) {
            IHubPeripheryRegistry(hubPeripheryRegistry).setDepositorBeacon(implemIds[i], depositorBeacons[i]);
        }
    }

    function registerRedeemerBeacons(
        address hubPeripheryRegistry,
        uint16[] memory implemIds,
        address[] memory redeemerBeacons
    ) public {
        require(implemIds.length == redeemerBeacons.length, "Mismatched lengths");

        for (uint256 i; i < implemIds.length; ++i) {
            IHubPeripheryRegistry(hubPeripheryRegistry).setRedeemerBeacon(implemIds[i], redeemerBeacons[i]);
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
