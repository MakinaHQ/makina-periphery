// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {IAccessManager} from "@openzeppelin/contracts/access/manager/IAccessManager.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";

import {ProxyUtils} from "@makina-core-test/utils/ProxyUtils.sol";
import {ICoreRegistry} from "@makina-core/interfaces/ICoreRegistry.sol";
import {Roles} from "@makina-core/libraries/Roles.sol";

import {IHubPeripheryRegistry} from "../../src/interfaces/IHubPeripheryRegistry.sol";
import {FlashloanAggregator} from "../../src/flashloans/FlashloanAggregator.sol";
import {HubPeripheryRegistry} from "../../src/registries/HubPeripheryRegistry.sol";
import {HubPeripheryFactory} from "../../src/factories/HubPeripheryFactory.sol";
import {WatermarkFeeManager} from "../../src/fee-managers/WatermarkFeeManager.sol";
import {DirectDepositor} from "../../src/depositors/DirectDepositor.sol";
import {AsyncRedeemer} from "../../src/redeemers/AsyncRedeemer.sol";
import {AsyncRedeemerFee} from "../../src/redeemers/AsyncRedeemerFee.sol";
import {SecurityModule} from "../../src/security-module/SecurityModule.sol";
import {MachineShareOracle} from "../../src/oracles/MachineShareOracle.sol";
import {MachineShareOracleFactory} from "../../src/factories/MachineShareOracleFactory.sol";
import {MetaMorphoOracleFactory} from "../../src/factories/MetaMorphoOracleFactory.sol";

abstract contract Base is ProxyUtils {
    struct HubPeriphery {
        FlashloanAggregator flashloanAggregator;
        HubPeripheryRegistry hubPeripheryRegistry;
        HubPeripheryFactory hubPeripheryFactory;
        UpgradeableBeacon directDepositorBeacon;
        UpgradeableBeacon asyncRedeemerBeacon;
        UpgradeableBeacon asyncRedeemerFeeBeacon;
        UpgradeableBeacon watermarkFeeManagerBeacon;
        UpgradeableBeacon securityModuleBeacon;
        MetaMorphoOracleFactory metaMorphoOracleFactory;
        UpgradeableBeacon machineShareOracleBeacon;
        MachineShareOracleFactory machineShareOracleFactory;
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

    function deployHubPeriphery(address accessManager, address hubCoreRegistry, FlashloanProviders memory flProviders)
        internal
        returns (HubPeriphery memory deployment)
    {
        {
            address caliberFactory = ICoreRegistry(hubCoreRegistry).coreFactory();
            deployment.flashloanAggregator = deployFlashloanAggregator(caliberFactory, flProviders);
        }

        {
            address hubPeripheryRegistryImplemAddr = address(new HubPeripheryRegistry());
            deployment.hubPeripheryRegistry = HubPeripheryRegistry(
                address(
                    new TransparentUpgradeableProxy(
                        hubPeripheryRegistryImplemAddr,
                        accessManager,
                        abi.encodeCall(HubPeripheryRegistry.initialize, (accessManager))
                    )
                )
            );
        }

        {
            address hubPeripheryFactoryImplemAddr =
                address(new HubPeripheryFactory(address(deployment.hubPeripheryRegistry)));
            deployment.hubPeripheryFactory = HubPeripheryFactory(
                address(
                    new TransparentUpgradeableProxy(
                        hubPeripheryFactoryImplemAddr,
                        accessManager,
                        abi.encodeCall(HubPeripheryFactory.initialize, (accessManager))
                    )
                )
            );
        }

        {
            address directDepositorImplemAddr = address(new DirectDepositor(address(deployment.hubPeripheryRegistry)));
            deployment.directDepositorBeacon = new UpgradeableBeacon(directDepositorImplemAddr, accessManager);
        }

        {
            address asyncRedeemerImplemAddr = address(new AsyncRedeemer(address(deployment.hubPeripheryRegistry)));
            deployment.asyncRedeemerBeacon = new UpgradeableBeacon(asyncRedeemerImplemAddr, accessManager);
        }

        {
            address asyncRedeemerFeeImplemAddr = address(new AsyncRedeemerFee(address(deployment.hubPeripheryRegistry)));
            deployment.asyncRedeemerFeeBeacon = new UpgradeableBeacon(asyncRedeemerFeeImplemAddr, accessManager);
        }

        {
            address watermarkFeeManagerImplemAddr =
                address(new WatermarkFeeManager(address(deployment.hubPeripheryRegistry)));
            deployment.watermarkFeeManagerBeacon = new UpgradeableBeacon(watermarkFeeManagerImplemAddr, accessManager);
        }

        {
            address securityModuleImplemAddr = address(new SecurityModule(address(deployment.hubPeripheryRegistry)));
            deployment.securityModuleBeacon = new UpgradeableBeacon(securityModuleImplemAddr, accessManager);
        }

        {
            address metaMorphoOracleFactoryImplemAddr = address(new MetaMorphoOracleFactory());
            deployment.metaMorphoOracleFactory = MetaMorphoOracleFactory(
                address(
                    new TransparentUpgradeableProxy(
                        metaMorphoOracleFactoryImplemAddr,
                        accessManager,
                        abi.encodeCall(MetaMorphoOracleFactory.initialize, (accessManager))
                    )
                )
            );
        }

        {
            address machineOracleImplemAddr = address(new MachineShareOracle(hubCoreRegistry));
            deployment.machineShareOracleBeacon = new UpgradeableBeacon(machineOracleImplemAddr, accessManager);
            address machineOracleFactoryImplemAddr = address(new MachineShareOracleFactory());
            deployment.machineShareOracleFactory = MachineShareOracleFactory(
                address(
                    new TransparentUpgradeableProxy(
                        machineOracleFactoryImplemAddr,
                        accessManager,
                        abi.encodeCall(
                            MachineShareOracleFactory.initialize,
                            (address(deployment.machineShareOracleBeacon), accessManager)
                        )
                    )
                )
            );
        }
    }

    function deployFlashloanAggregator(address caliberFactory, FlashloanProviders memory flProviders)
        internal
        virtual
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

    function registerFlashloanAggregator(address coreRegistry, address flashloanAggregator) internal {
        ICoreRegistry(coreRegistry).setFlashLoanModule(flashloanAggregator);
    }

    function registerHubPeripheryFactory(address hubPeripheryRegistry, address hubPeripheryFactory) internal {
        IHubPeripheryRegistry(hubPeripheryRegistry).setPeripheryFactory(hubPeripheryFactory);
    }

    function registerSecurityModuleBeacon(address hubPeripheryRegistry, address securityModuleBeacon) internal {
        IHubPeripheryRegistry(hubPeripheryRegistry).setSecurityModuleBeacon(securityModuleBeacon);
    }

    function registerDepositorBeacons(
        address hubPeripheryRegistry,
        uint16[] memory implemIds,
        address[] memory depositorBeacons
    ) internal {
        require(implemIds.length == depositorBeacons.length, "Mismatched lengths");

        for (uint256 i; i < implemIds.length; ++i) {
            IHubPeripheryRegistry(hubPeripheryRegistry).setDepositorBeacon(implemIds[i], depositorBeacons[i]);
        }
    }

    function registerRedeemerBeacons(
        address hubPeripheryRegistry,
        uint16[] memory implemIds,
        address[] memory redeemerBeacons
    ) internal {
        require(implemIds.length == redeemerBeacons.length, "Mismatched lengths");

        for (uint256 i; i < implemIds.length; ++i) {
            IHubPeripheryRegistry(hubPeripheryRegistry).setRedeemerBeacon(implemIds[i], redeemerBeacons[i]);
        }
    }

    function registerFeeManagerBeacons(
        address hubPeripheryRegistry,
        uint16[] memory implemIds,
        address[] memory feeManagerBeacons
    ) internal {
        require(implemIds.length == feeManagerBeacons.length, "Mismatched lengths");

        for (uint256 i; i < implemIds.length; ++i) {
            IHubPeripheryRegistry(hubPeripheryRegistry).setFeeManagerBeacon(implemIds[i], feeManagerBeacons[i]);
        }
    }

    ///
    /// ACCESS MANAGER SETUP
    ///

    function setupHubPeripheryAMFunctionRoles(address accessManager, HubPeriphery memory deployment) internal {
        // Transparent Proxy Admins
        bytes4[] memory proxyAdminSelectors = new bytes4[](1);
        proxyAdminSelectors[0] = ProxyAdmin.upgradeAndCall.selector;
        IAccessManager(accessManager)
            .setTargetFunctionRole(
                getProxyAdmin(address(deployment.hubPeripheryRegistry)), proxyAdminSelectors, Roles.INFRA_UPGRADE_ROLE
            );
        IAccessManager(accessManager)
            .setTargetFunctionRole(
                getProxyAdmin(address(deployment.hubPeripheryFactory)), proxyAdminSelectors, Roles.INFRA_UPGRADE_ROLE
            );
        IAccessManager(accessManager)
            .setTargetFunctionRole(
                getProxyAdmin(address(deployment.metaMorphoOracleFactory)),
                proxyAdminSelectors,
                Roles.INFRA_UPGRADE_ROLE
            );
        IAccessManager(accessManager)
            .setTargetFunctionRole(
                getProxyAdmin(address(deployment.machineShareOracleFactory)),
                proxyAdminSelectors,
                Roles.INFRA_UPGRADE_ROLE
            );

        // Upgradeable Beacons
        bytes4[] memory beaconSelectors = new bytes4[](1);
        beaconSelectors[0] = UpgradeableBeacon.upgradeTo.selector;
        IAccessManager(accessManager)
            .setTargetFunctionRole(address(deployment.directDepositorBeacon), beaconSelectors, Roles.INFRA_UPGRADE_ROLE);
        IAccessManager(accessManager)
            .setTargetFunctionRole(address(deployment.asyncRedeemerBeacon), beaconSelectors, Roles.INFRA_UPGRADE_ROLE);
        IAccessManager(accessManager)
            .setTargetFunctionRole(
                address(deployment.watermarkFeeManagerBeacon), beaconSelectors, Roles.INFRA_UPGRADE_ROLE
            );
        IAccessManager(accessManager)
            .setTargetFunctionRole(address(deployment.securityModuleBeacon), beaconSelectors, Roles.INFRA_UPGRADE_ROLE);
        IAccessManager(accessManager)
            .setTargetFunctionRole(
                address(deployment.machineShareOracleBeacon), beaconSelectors, Roles.INFRA_UPGRADE_ROLE
            );

        // HubPeripheryRegistry
        bytes4[] memory hubPeripheryRegistrySelectors = new bytes4[](10);
        hubPeripheryRegistrySelectors[0] = IHubPeripheryRegistry.setPeripheryFactory.selector;
        hubPeripheryRegistrySelectors[1] = IHubPeripheryRegistry.setDepositorBeacon.selector;
        hubPeripheryRegistrySelectors[2] = IHubPeripheryRegistry.setRedeemerBeacon.selector;
        hubPeripheryRegistrySelectors[3] = IHubPeripheryRegistry.setFeeManagerBeacon.selector;
        hubPeripheryRegistrySelectors[4] = IHubPeripheryRegistry.setSecurityModuleBeacon.selector;
        IAccessManager(accessManager)
            .setTargetFunctionRole(
                address(deployment.hubPeripheryRegistry), hubPeripheryRegistrySelectors, Roles.INFRA_UPGRADE_ROLE
            );

        // HubPeripheryFactory
        bytes4[] memory hubPeripheryFactorySelectors = new bytes4[](6);
        hubPeripheryFactorySelectors[0] = HubPeripheryFactory.setMachine.selector;
        hubPeripheryFactorySelectors[1] = HubPeripheryFactory.setSecurityModule.selector;
        hubPeripheryFactorySelectors[2] = HubPeripheryFactory.createDepositor.selector;
        hubPeripheryFactorySelectors[3] = HubPeripheryFactory.createRedeemer.selector;
        hubPeripheryFactorySelectors[4] = HubPeripheryFactory.createFeeManager.selector;
        hubPeripheryFactorySelectors[5] = HubPeripheryFactory.createSecurityModule.selector;
        IAccessManager(accessManager)
            .setTargetFunctionRole(
                address(deployment.hubPeripheryFactory), hubPeripheryFactorySelectors, Roles.STRATEGY_DEPLOYMENT_ROLE
            );

        // MetaMorphoOracleFactory
        bytes4[] memory metaMorphoOracleFactorySelectors = new bytes4[](2);
        metaMorphoOracleFactorySelectors[0] = MetaMorphoOracleFactory.setMorphoFactory.selector;
        metaMorphoOracleFactorySelectors[1] = MetaMorphoOracleFactory.createMetaMorphoOracle.selector;
        IAccessManager(accessManager)
            .setTargetFunctionRole(
                address(deployment.metaMorphoOracleFactory), metaMorphoOracleFactorySelectors, Roles.INFRA_CONFIG_ROLE
            );

        // MachineShareOracleFactory
        bytes4[] memory machineShareOracleFactorySelectors = new bytes4[](1);
        machineShareOracleFactorySelectors[0] = MachineShareOracleFactory.setMachineShareOracleBeacon.selector;
        IAccessManager(accessManager)
            .setTargetFunctionRole(
                address(deployment.machineShareOracleFactory),
                machineShareOracleFactorySelectors,
                Roles.INFRA_UPGRADE_ROLE
            );
        machineShareOracleFactorySelectors[0] = MachineShareOracleFactory.createMachineShareOracle.selector;
        IAccessManager(accessManager)
            .setTargetFunctionRole(
                address(deployment.machineShareOracleFactory),
                machineShareOracleFactorySelectors,
                Roles.INFRA_CONFIG_ROLE
            );
    }
}
