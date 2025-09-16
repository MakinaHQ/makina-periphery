// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {AccessManagerUpgradeable} from "@openzeppelin/contracts-upgradeable/access/manager/AccessManagerUpgradeable.sol";
import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import "@makina-core-test/base/Base.sol" as Core_base;
import "@makina-core-test/utils/Constants.sol" as Core_Constants;

import {MockWormhole} from "@makina-core-test/mocks/MockWormhole.sol";
import {Caliber} from "@makina-core/caliber/Caliber.sol";
import {ChainRegistry} from "@makina-core/registries/ChainRegistry.sol";
import {HubCoreRegistry} from "@makina-core/registries/HubCoreRegistry.sol";
import {Machine} from "@makina-core/machine/Machine.sol";
import {HubCoreFactory} from "@makina-core/factories/HubCoreFactory.sol";
import {OracleRegistry} from "@makina-core/registries/OracleRegistry.sol";
import {PreDepositVault} from "@makina-core/pre-deposit/PreDepositVault.sol";
import {SwapModule} from "@makina-core/swap/SwapModule.sol";
import {TokenRegistry} from "@makina-core/registries/TokenRegistry.sol";

abstract contract CoreHelpers is Core_Constants.Constants {
    function _deployWormhole(uint16 wormholeHubChainId, uint256 hubChainId) internal returns (MockWormhole wormhole) {
        return new MockWormhole(wormholeHubChainId, hubChainId);
    }

    function _deployHubCore(address deployer, address dao, address wormhole)
        internal
        returns (Core_base.Base.HubCore memory deployment)
    {
        address accessManagerImplemAddr = address(new AccessManagerUpgradeable());
        deployment.accessManager = AccessManagerUpgradeable(
            address(
                new TransparentUpgradeableProxy(
                    accessManagerImplemAddr, dao, abi.encodeCall(AccessManagerUpgradeable.initialize, (deployer))
                )
            )
        );

        address oracleRegistryImplemAddr = address(new OracleRegistry());
        deployment.oracleRegistry = OracleRegistry(
            address(
                new TransparentUpgradeableProxy(
                    oracleRegistryImplemAddr,
                    dao,
                    abi.encodeCall(OracleRegistry.initialize, (address(deployment.accessManager)))
                )
            )
        );

        address tokenRegistryImplemAddr = address(new TokenRegistry());
        deployment.tokenRegistry = TokenRegistry(
            address(
                new TransparentUpgradeableProxy(
                    tokenRegistryImplemAddr,
                    dao,
                    abi.encodeCall(TokenRegistry.initialize, (address(deployment.accessManager)))
                )
            )
        );

        address chainRegistryImplemAddr = address(new ChainRegistry());
        deployment.chainRegistry = ChainRegistry(
            address(
                new TransparentUpgradeableProxy(
                    chainRegistryImplemAddr,
                    dao,
                    abi.encodeCall(ChainRegistry.initialize, (address(deployment.accessManager)))
                )
            )
        );

        address hubCoreRegistryImplemAddr = address(new HubCoreRegistry());
        deployment.hubCoreRegistry = HubCoreRegistry(
            address(
                new TransparentUpgradeableProxy(
                    hubCoreRegistryImplemAddr,
                    dao,
                    abi.encodeCall(
                        HubCoreRegistry.initialize,
                        (
                            address(deployment.oracleRegistry),
                            address(deployment.tokenRegistry),
                            address(deployment.chainRegistry),
                            address(deployment.accessManager)
                        )
                    )
                )
            )
        );

        address swapModuleImplemAddr = address(new SwapModule(address(deployment.hubCoreRegistry)));
        deployment.swapModule = SwapModule(
            address(
                new TransparentUpgradeableProxy(
                    swapModuleImplemAddr,
                    dao,
                    abi.encodeCall(SwapModule.initialize, (address(deployment.accessManager)))
                )
            )
        );

        address caliberImplemAddr = address(new Caliber(address(deployment.hubCoreRegistry), address(0)));
        deployment.caliberBeacon = new UpgradeableBeacon(caliberImplemAddr, dao);

        address machineImplemAddr = address(new Machine(address(deployment.hubCoreRegistry), address(wormhole)));
        deployment.machineBeacon = new UpgradeableBeacon(machineImplemAddr, dao);

        address preDepositVaultImplemAddr = address(new PreDepositVault(address(deployment.hubCoreRegistry)));
        deployment.preDepositVaultBeacon = new UpgradeableBeacon(preDepositVaultImplemAddr, dao);

        address hubCoreFactoryImplemAddr = address(new HubCoreFactory(address(deployment.hubCoreRegistry)));
        deployment.hubCoreFactory = HubCoreFactory(
            address(
                new TransparentUpgradeableProxy(
                    hubCoreFactoryImplemAddr,
                    dao,
                    abi.encodeCall(HubCoreFactory.initialize, (address(deployment.accessManager)))
                )
            )
        );

        deployment.hubCoreRegistry.setSwapModule(address(deployment.swapModule));
        deployment.hubCoreRegistry.setTokenRegistry(address(deployment.tokenRegistry));
        deployment.hubCoreRegistry.setChainRegistry(address(deployment.chainRegistry));
        deployment.hubCoreRegistry.setCoreFactory(address(deployment.hubCoreFactory));
        deployment.hubCoreRegistry.setCaliberBeacon(address(deployment.caliberBeacon));
        deployment.hubCoreRegistry.setMachineBeacon(address(deployment.machineBeacon));
        deployment.hubCoreRegistry.setPreDepositVaultBeacon(address(deployment.preDepositVaultBeacon));
    }

    function _setupAccessManager(AccessManagerUpgradeable accessManager, address dao) internal {
        accessManager.grantRole(accessManager.ADMIN_ROLE(), dao, 0);
        accessManager.revokeRole(accessManager.ADMIN_ROLE(), address(this));
    }
}
