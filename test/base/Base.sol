// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {IAccessManager} from "@openzeppelin/contracts/access/manager/IAccessManager.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";

import "@makina-core-test/base/Base.sol" as Core_Base;
import {ProxyUtils} from "@makina-core-test/utils/ProxyUtils.sol";
import {ICoreRegistry} from "@makina-core/interfaces/ICoreRegistry.sol";
import {Roles} from "@makina-core/libraries/Roles.sol";

import {AsyncRedeemer} from "../../src/redeemers/AsyncRedeemer.sol";
import {AsyncRedeemerFee} from "../../src/redeemers/AsyncRedeemerFee.sol";
import {DirectDepositor} from "../../src/depositors/DirectDepositor.sol";
import {FlashloanAggregator} from "../../src/flashloans/FlashloanAggregator.sol";
import {HubPeripheryRegistry} from "../../src/registries/HubPeripheryRegistry.sol";
import {HubPeripheryFactory} from "../../src/factories/HubPeripheryFactory.sol";
import {IHubPeripheryRegistry} from "../../src/interfaces/IHubPeripheryRegistry.sol";
import {JsonParser} from "../utils/JsonParser.sol";
import {MachineShareOracle} from "../../src/oracles/MachineShareOracle.sol";
import {MachineShareOracleFactory} from "../../src/factories/MachineShareOracleFactory.sol";
import {MetaMorphoOracleFactory} from "../../src/factories/MetaMorphoOracleFactory.sol";
import {SaltDomains} from "../utils/SaltDomains.sol";
import {SecurityModule} from "../../src/security-module/SecurityModule.sol";
import {WatermarkFeeManager} from "../../src/fee-managers/WatermarkFeeManager.sol";

abstract contract Base is ProxyUtils, JsonParser, SaltDomains, Core_Base.Base {
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

    ///
    /// HUB PERIPHERY DEPLOYMENTS
    ///

    function deployHubPeriphery(
        address accessManager,
        address hubCoreRegistry,
        address sanctionsOracle,
        FlashloanProviders memory flProviders
    ) internal returns (HubPeriphery memory deployment) {
        // Flashloan Aggregator
        deployment.flashloanAggregator =
            _deployFlashloanAggregator(ICoreRegistry(hubCoreRegistry).coreFactory(), flProviders);

        // Hub Periphery Registry
        deployment.hubPeripheryRegistry = _deployHubPeripheryRegistry(accessManager, accessManager);

        // Hub Periphery Factory
        deployment.hubPeripheryFactory =
            _deployHubPeripheryFactory(accessManager, address(deployment.hubPeripheryRegistry), accessManager);

        // Direct Depositor Beacon
        deployment.directDepositorBeacon =
            _deployDirectDepositorBeacon(accessManager, address(deployment.hubPeripheryRegistry), sanctionsOracle);

        // Async Redeemer Beacon
        deployment.asyncRedeemerBeacon =
            _deployAsyncRedeemerBeacon(accessManager, address(deployment.hubPeripheryRegistry), sanctionsOracle);

        // Async Redeemer Fee Beacon
        deployment.asyncRedeemerFeeBeacon =
            _deployAsyncRedeemerFeeBeacon(accessManager, address(deployment.hubPeripheryRegistry), sanctionsOracle);

        // Watermark Fee Manager Beacon
        deployment.watermarkFeeManagerBeacon =
            _deployWatermarkFeeManagerBeacon(accessManager, address(deployment.hubPeripheryRegistry));

        // Security Module Beacon
        deployment.securityModuleBeacon =
            _deploySecurityModuleBeacon(accessManager, address(deployment.hubPeripheryRegistry));

        // MetaMorpho Oracle Factory
        deployment.metaMorphoOracleFactory = _deployMetaMorphoOracleFactory(accessManager, accessManager);

        // Machine Share Oracle Beacon
        deployment.machineShareOracleBeacon = _deployMachineShareOracleBeacon(accessManager, hubCoreRegistry);

        // Machine Share Oracle Factory
        deployment.machineShareOracleFactory = _deployMachineShareOracleFactory(
            accessManager, address(deployment.machineShareOracleBeacon), accessManager
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
                address(deployment.asyncRedeemerFeeBeacon), beaconSelectors, Roles.INFRA_UPGRADE_ROLE
            );
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
        bytes4[] memory hubPeripheryRegistrySelectors = new bytes4[](5);
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

    ///
    /// DEPLOYMENT UTILS
    ///

    function _deployFlashloanAggregator(address _caliberFactory, FlashloanProviders memory _flProviders)
        internal
        returns (FlashloanAggregator)
    {
        return FlashloanAggregator(
            _deployCode(
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
                FLASHLOAN_AGGREGATOR_SALT_DOMAIN
            )
        );
    }

    function _deployHubPeripheryRegistry(address _proxyOwner, address _accessManager)
        internal
        returns (HubPeripheryRegistry)
    {
        address implem = _deployCode(type(HubPeripheryRegistry).creationCode, 0);
        return HubPeripheryRegistry(
            _deployCode(
                abi.encodePacked(
                    type(TransparentUpgradeableProxy).creationCode,
                    abi.encode(implem, _proxyOwner, abi.encodeCall(HubPeripheryRegistry.initialize, (_accessManager)))
                ),
                PERIPHERY_REGISTRY_SALT_DOMAIN
            )
        );
    }

    function _deployHubPeripheryFactory(address _proxyOwner, address _hubPeripheryRegistry, address _accessManager)
        internal
        returns (HubPeripheryFactory)
    {
        address implem =
            _deployCode(abi.encodePacked(type(HubPeripheryFactory).creationCode, abi.encode(_hubPeripheryRegistry)), 0);
        return HubPeripheryFactory(
            _deployCode(
                abi.encodePacked(
                    type(TransparentUpgradeableProxy).creationCode,
                    abi.encode(implem, _proxyOwner, abi.encodeCall(HubPeripheryFactory.initialize, (_accessManager)))
                ),
                PERIPHERY_FACTORY_SALT_DOMAIN
            )
        );
    }

    function _deployDirectDepositorBeacon(address _beaconOwner, address _hubPeripheryRegistry, address _sanctionsOracle)
        internal
        returns (UpgradeableBeacon)
    {
        address implem = _deployCode(
            abi.encodePacked(type(DirectDepositor).creationCode, abi.encode(_hubPeripheryRegistry, _sanctionsOracle)), 0
        );
        return UpgradeableBeacon(
            _deployCode(
                abi.encodePacked(type(UpgradeableBeacon).creationCode, abi.encode(implem, _beaconOwner)),
                DIRECT_DEPOSITOR_SALT_DOMAIN
            )
        );
    }

    function _deployAsyncRedeemerBeacon(address _beaconOwner, address _hubPeripheryRegistry, address _sanctionsOracle)
        internal
        returns (UpgradeableBeacon)
    {
        address implem = _deployCode(
            abi.encodePacked(type(AsyncRedeemer).creationCode, abi.encode(_hubPeripheryRegistry, _sanctionsOracle)), 0
        );
        return UpgradeableBeacon(
            _deployCode(
                abi.encodePacked(type(UpgradeableBeacon).creationCode, abi.encode(implem, _beaconOwner)),
                ASYNC_REDEEMER_SALT_DOMAIN
            )
        );
    }

    function _deployAsyncRedeemerFeeBeacon(
        address _beaconOwner,
        address _hubPeripheryRegistry,
        address _sanctionsOracle
    ) internal returns (UpgradeableBeacon) {
        address implem = _deployCode(
            abi.encodePacked(type(AsyncRedeemerFee).creationCode, abi.encode(_hubPeripheryRegistry, _sanctionsOracle)),
            0
        );
        return UpgradeableBeacon(
            _deployCode(
                abi.encodePacked(type(UpgradeableBeacon).creationCode, abi.encode(implem, _beaconOwner)),
                ASYNC_REDEEMER_FEE_SALT_DOMAIN
            )
        );
    }

    function _deployWatermarkFeeManagerBeacon(address _beaconOwner, address _hubPeripheryRegistry)
        internal
        returns (UpgradeableBeacon)
    {
        address implem = _deployCode(
            abi.encodePacked(type(WatermarkFeeManager).creationCode, abi.encode(_hubPeripheryRegistry)), 0
        );
        return UpgradeableBeacon(
            _deployCode(
                abi.encodePacked(type(UpgradeableBeacon).creationCode, abi.encode(implem, _beaconOwner)),
                WATERMARK_FEE_MANAGER_SALT_DOMAIN
            )
        );
    }

    function _deploySecurityModuleBeacon(address _beaconOwner, address _hubPeripheryRegistry)
        internal
        returns (UpgradeableBeacon)
    {
        address implem = _deployCode(
            abi.encodePacked(type(SecurityModule).creationCode, abi.encode(_hubPeripheryRegistry)), 0
        );
        return UpgradeableBeacon(
            _deployCode(
                abi.encodePacked(type(UpgradeableBeacon).creationCode, abi.encode(implem, _beaconOwner)),
                SECURITY_MODULE_SALT_DOMAIN
            )
        );
    }

    function _deployMetaMorphoOracleFactory(address _proxyOwner, address _accessManager)
        internal
        returns (MetaMorphoOracleFactory)
    {
        address implem = _deployCode(type(MetaMorphoOracleFactory).creationCode, 0);
        return MetaMorphoOracleFactory(
            _deployCode(
                abi.encodePacked(
                    type(TransparentUpgradeableProxy).creationCode,
                    abi.encode(
                        implem, _proxyOwner, abi.encodeCall(MetaMorphoOracleFactory.initialize, (_accessManager))
                    )
                ),
                META_MORPHO_ORACLE_FACTORY_SALT_DOMAIN
            )
        );
    }

    function _deployMachineShareOracleBeacon(address _beaconOwner, address _hubCoreRegistry)
        internal
        returns (UpgradeableBeacon)
    {
        address implem = _deployCode(
            abi.encodePacked(type(MachineShareOracle).creationCode, abi.encode(_hubCoreRegistry)), 0
        );
        return UpgradeableBeacon(
            _deployCode(
                abi.encodePacked(type(UpgradeableBeacon).creationCode, abi.encode(implem, _beaconOwner)),
                MACHINE_SHARE_ORACLE_SALT_DOMAIN
            )
        );
    }

    function _deployMachineShareOracleFactory(
        address _proxyOwner,
        address _machineShareOracleBeacon,
        address _accessManager
    ) internal returns (MachineShareOracleFactory) {
        address implem = _deployCode(type(MachineShareOracleFactory).creationCode, 0);
        return MachineShareOracleFactory(
            _deployCode(
                abi.encodePacked(
                    type(TransparentUpgradeableProxy).creationCode,
                    abi.encode(
                        implem,
                        _proxyOwner,
                        abi.encodeCall(
                            MachineShareOracleFactory.initialize, (_machineShareOracleBeacon, _accessManager)
                        )
                    )
                ),
                MACHINE_SHARE_ORACLE_FACTORY_SALT_DOMAIN
            )
        );
    }
}
