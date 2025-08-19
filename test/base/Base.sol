// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.28;

import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";

import {ICoreRegistry} from "@makina-core/interfaces/ICoreRegistry.sol";
import {IHubPeripheryRegistry} from "../../src/interfaces/IHubPeripheryRegistry.sol";

import {FlashloanAggregator} from "../../src/flashloans/FlashloanAggregator.sol";
import {HubPeripheryRegistry} from "../../src/registries/HubPeripheryRegistry.sol";
import {HubPeripheryFactory} from "../../src/factories/HubPeripheryFactory.sol";
import {OpenMachineDepositor} from "../../src/depositors/OpenMachineDepositor.sol";
import {WhitelistMachineDepositor} from "../../src/depositors/WhitelistMachineDepositor.sol";
import {AsyncMachineRedeemer} from "../../src/redeemers/AsyncMachineRedeemer.sol";
import {WhitelistAsyncMachineRedeemer} from "../../src/redeemers/WhitelistAsyncMachineRedeemer.sol";
import {StakingModule} from "../../src/staking-module/StakingModule.sol";

abstract contract Base {
    struct HubPeriphery {
        FlashloanAggregator flashloanAggregator;
        HubPeripheryRegistry hubPeripheryRegistry;
        HubPeripheryFactory hubPeripheryFactory;
        UpgradeableBeacon openMachineDepositorBeacon;
        UpgradeableBeacon whitelistMachineDepositorBeacon;
        UpgradeableBeacon asyncMachineRedeemerBeacon;
        UpgradeableBeacon whitelistAsyncMachineRedeemerBeacon;
        UpgradeableBeacon stakingModuleBeacon;
    }

    struct FlashLoanAggregatorInitParams {
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

    function deployPeriphery(
        address accessManager,
        address coreFactory,
        address dao,
        FlashLoanAggregatorInitParams memory flProviders
    ) public returns (HubPeriphery memory deployment) {
        deployment.flashloanAggregator = new FlashloanAggregator(
            coreFactory,
            flProviders.balancerV2Pool,
            flProviders.balancerV3Pool,
            flProviders.morphoPool,
            flProviders.dssFlash,
            flProviders.aaveV3AddressProvider,
            flProviders.dai
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
        address openMachineDepositorImplemAddr =
            address(new OpenMachineDepositor(address(deployment.hubPeripheryRegistry)));
        deployment.openMachineDepositorBeacon = new UpgradeableBeacon(openMachineDepositorImplemAddr, dao);

        address whitelistMachineDepositorImplemAddr =
            address(new WhitelistMachineDepositor(address(deployment.hubPeripheryRegistry)));
        deployment.whitelistMachineDepositorBeacon = new UpgradeableBeacon(whitelistMachineDepositorImplemAddr, dao);

        address asyncMachineRedeemerImplemAddr =
            address(new AsyncMachineRedeemer(address(deployment.hubPeripheryRegistry)));
        deployment.asyncMachineRedeemerBeacon = new UpgradeableBeacon(asyncMachineRedeemerImplemAddr, dao);

        address whitelistAsyncMachineRedeemerImplemAddr =
            address(new WhitelistAsyncMachineRedeemer(address(deployment.hubPeripheryRegistry)));
        deployment.whitelistAsyncMachineRedeemerBeacon =
            new UpgradeableBeacon(whitelistAsyncMachineRedeemerImplemAddr, dao);

        address stakingModuleImplemAddr = address(new StakingModule(address(deployment.hubPeripheryRegistry)));
        deployment.stakingModuleBeacon = new UpgradeableBeacon(stakingModuleImplemAddr, dao);
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

    function registerStakingModuleBeacon(address hubPeripheryRegistry, address stakingModuleBeacon) public {
        IHubPeripheryRegistry(hubPeripheryRegistry).setStakingModuleBeacon(stakingModuleBeacon);
    }

    function registerMachineDepositorBeacons(
        address hubPeripheryRegistry,
        uint16[] memory implemIds,
        address[] memory machineDepositorBeacons
    ) public {
        require(implemIds.length == machineDepositorBeacons.length, "Mismatched lengths");

        for (uint256 i; i < implemIds.length; ++i) {
            IHubPeripheryRegistry(hubPeripheryRegistry).setMachineDepositorBeacon(
                implemIds[i], machineDepositorBeacons[i]
            );
        }
    }

    function registerMachineRedeemerBeacons(
        address hubPeripheryRegistry,
        uint16[] memory implemIds,
        address[] memory machineRedeemerBeacons
    ) public {
        require(implemIds.length == machineRedeemerBeacons.length, "Mismatched lengths");

        for (uint256 i; i < implemIds.length; ++i) {
            IHubPeripheryRegistry(hubPeripheryRegistry).setMachineRedeemerBeacon(
                implemIds[i], machineRedeemerBeacons[i]
            );
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
