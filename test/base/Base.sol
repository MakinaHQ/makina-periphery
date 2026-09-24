// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {IAccessManager} from "@openzeppelin/contracts/access/manager/IAccessManager.sol";
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

    /// @dev A `setTargetFunctionRole` assignment, `targetName` labelling it in logs.
    struct AMFunctionRole {
        string targetName;
        address target;
        bytes4[] selectors;
        uint64 roleId;
    }

    function setupHubPeripheryAMFunctionRoles(address accessManager, HubPeriphery memory deployment) internal {
        AMFunctionRole[] memory functionRoles = hubPeripheryAMFunctionRoles(deployment);
        for (uint256 i; i < functionRoles.length; ++i) {
            IAccessManager(accessManager)
                .setTargetFunctionRole(functionRoles[i].target, functionRoles[i].selectors, functionRoles[i].roleId);
        }
    }

    /// @dev The AccessManager function roles of a hub periphery, in setup order. Single source for the setup above
    ///      and for the calls the setup script broadcasts or logs, so that the two cannot drift apart.
    function hubPeripheryAMFunctionRoles(HubPeriphery memory deployment)
        internal
        view
        returns (AMFunctionRole[] memory functionRoles)
    {
        functionRoles = new AMFunctionRole[](15);

        // Transparent Proxy Admins
        bytes4[] memory proxyAdminSelectors = _proxyAdminAMSelectors();
        functionRoles[0] = AMFunctionRole(
            "ProxyAdmin of HubPeripheryRegistry",
            getProxyAdmin(address(deployment.hubPeripheryRegistry)),
            proxyAdminSelectors,
            Roles.INFRA_UPGRADE_ROLE
        );
        functionRoles[1] = AMFunctionRole(
            "ProxyAdmin of HubPeripheryFactory",
            getProxyAdmin(address(deployment.hubPeripheryFactory)),
            proxyAdminSelectors,
            Roles.INFRA_UPGRADE_ROLE
        );
        functionRoles[2] = AMFunctionRole(
            "ProxyAdmin of MetaMorphoOracleFactory",
            getProxyAdmin(address(deployment.metaMorphoOracleFactory)),
            proxyAdminSelectors,
            Roles.INFRA_UPGRADE_ROLE
        );
        functionRoles[3] = AMFunctionRole(
            "ProxyAdmin of MachineShareOracleFactory",
            getProxyAdmin(address(deployment.machineShareOracleFactory)),
            proxyAdminSelectors,
            Roles.INFRA_UPGRADE_ROLE
        );

        // Upgradeable Beacons
        bytes4[] memory beaconSelectors = _beaconAMSelectors();
        functionRoles[4] = AMFunctionRole(
            "DirectDepositorBeacon",
            address(deployment.directDepositorBeacon),
            beaconSelectors,
            Roles.INFRA_UPGRADE_ROLE
        );
        functionRoles[5] = AMFunctionRole(
            "AsyncRedeemerBeacon", address(deployment.asyncRedeemerBeacon), beaconSelectors, Roles.INFRA_UPGRADE_ROLE
        );
        functionRoles[6] = AMFunctionRole(
            "AsyncRedeemerFeeBeacon",
            address(deployment.asyncRedeemerFeeBeacon),
            beaconSelectors,
            Roles.INFRA_UPGRADE_ROLE
        );
        functionRoles[7] = AMFunctionRole(
            "WatermarkFeeManagerBeacon",
            address(deployment.watermarkFeeManagerBeacon),
            beaconSelectors,
            Roles.INFRA_UPGRADE_ROLE
        );
        functionRoles[8] = AMFunctionRole(
            "SecurityModuleBeacon", address(deployment.securityModuleBeacon), beaconSelectors, Roles.INFRA_UPGRADE_ROLE
        );
        functionRoles[9] = AMFunctionRole(
            "MachineShareOracleBeacon",
            address(deployment.machineShareOracleBeacon),
            beaconSelectors,
            Roles.INFRA_UPGRADE_ROLE
        );

        // Registry and factories
        functionRoles[10] = AMFunctionRole(
            "HubPeripheryRegistry",
            address(deployment.hubPeripheryRegistry),
            _hubPeripheryRegistryAMSelectors(),
            Roles.INFRA_UPGRADE_ROLE
        );
        functionRoles[11] = AMFunctionRole(
            "HubPeripheryFactory",
            address(deployment.hubPeripheryFactory),
            _hubPeripheryFactoryAMSelectors(),
            Roles.STRATEGY_DEPLOYMENT_ROLE
        );
        functionRoles[12] = AMFunctionRole(
            "MetaMorphoOracleFactory",
            address(deployment.metaMorphoOracleFactory),
            _metaMorphoOracleFactoryAMSelectors(),
            Roles.INFRA_CONFIG_ROLE
        );
        functionRoles[13] = AMFunctionRole(
            "MachineShareOracleFactory (upgrade)",
            address(deployment.machineShareOracleFactory),
            _machineShareOracleFactoryUpgradeAMSelectors(),
            Roles.INFRA_UPGRADE_ROLE
        );
        functionRoles[14] = AMFunctionRole(
            "MachineShareOracleFactory (config)",
            address(deployment.machineShareOracleFactory),
            _machineShareOracleFactoryConfigAMSelectors(),
            Roles.INFRA_CONFIG_ROLE
        );
    }

    function _hubPeripheryRegistryAMSelectors() internal pure returns (bytes4[] memory selectors) {
        selectors = new bytes4[](5);
        selectors[0] = IHubPeripheryRegistry.setPeripheryFactory.selector;
        selectors[1] = IHubPeripheryRegistry.setDepositorBeacon.selector;
        selectors[2] = IHubPeripheryRegistry.setRedeemerBeacon.selector;
        selectors[3] = IHubPeripheryRegistry.setFeeManagerBeacon.selector;
        selectors[4] = IHubPeripheryRegistry.setSecurityModuleBeacon.selector;
    }

    function _hubPeripheryFactoryAMSelectors() internal pure returns (bytes4[] memory selectors) {
        selectors = new bytes4[](6);
        selectors[0] = HubPeripheryFactory.setMachine.selector;
        selectors[1] = HubPeripheryFactory.setSecurityModule.selector;
        selectors[2] = HubPeripheryFactory.createDepositor.selector;
        selectors[3] = HubPeripheryFactory.createRedeemer.selector;
        selectors[4] = HubPeripheryFactory.createFeeManager.selector;
        selectors[5] = HubPeripheryFactory.createSecurityModule.selector;
    }

    function _metaMorphoOracleFactoryAMSelectors() internal pure returns (bytes4[] memory selectors) {
        selectors = new bytes4[](2);
        selectors[0] = MetaMorphoOracleFactory.setMorphoFactory.selector;
        selectors[1] = MetaMorphoOracleFactory.createMetaMorphoOracle.selector;
    }

    function _machineShareOracleFactoryUpgradeAMSelectors() internal pure returns (bytes4[] memory selectors) {
        selectors = new bytes4[](1);
        selectors[0] = MachineShareOracleFactory.setMachineShareOracleBeacon.selector;
    }

    function _machineShareOracleFactoryConfigAMSelectors() internal pure returns (bytes4[] memory selectors) {
        selectors = new bytes4[](1);
        selectors[0] = MachineShareOracleFactory.createMachineShareOracle.selector;
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
