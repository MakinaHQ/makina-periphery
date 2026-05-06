// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {console} from "forge-std/console.sol";
import {stdJson} from "forge-std/StdJson.sol";

import {ICoreRegistry} from "@makina-core/interfaces/ICoreRegistry.sol";

import {UpgradePeriphery} from "./UpgradePeriphery.s.sol";

import {FlashloanAggregator} from "../../src/flashloans/FlashloanAggregator.sol";
import {HubPeripheryRegistry} from "../../src/registries/HubPeripheryRegistry.sol";
import {HubPeripheryFactory} from "../../src/factories/HubPeripheryFactory.sol";
import {DirectDepositor} from "../../src/depositors/DirectDepositor.sol";
import {AsyncRedeemer} from "../../src/redeemers/AsyncRedeemer.sol";
import {WatermarkFeeManager} from "../../src/fee-managers/WatermarkFeeManager.sol";
import {SecurityModule} from "../../src/security-module/SecurityModule.sol";
import {MetaMorphoOracleFactory} from "../../src/factories/MetaMorphoOracleFactory.sol";
import {MachineShareOracle} from "../../src/oracles/MachineShareOracle.sol";
import {MachineShareOracleFactory} from "../../src/factories/MachineShareOracleFactory.sol";

contract UpgradeHubPeriphery is UpgradePeriphery {
    using stdJson for string;

    struct HubPeriphery {
        address flashloanAggregator;
        address hubPeripheryRegistry;
        address hubPeripheryFactory;
        address directDepositorBeacon;
        address asyncRedeemerBeacon;
        address watermarkFeeManagerBeacon;
        address securityModuleBeacon;
        address metaMorphoOracleFactory;
        address machineShareOracleBeacon;
        address machineShareOracleFactory;
    }

    struct HubPeripheryImplems {
        address flashloanAggregator;
        address hubPeripheryRegistry;
        address hubPeripheryFactory;
        address directDepositor;
        address asyncRedeemer;
        address watermarkFeeManager;
        address securityModule;
        address metaMorphoOracleFactory;
        address machineShareOracle;
        address machineShareOracleFactory;
    }

    function _coreSetup() public override {
        // MAINNET PROD ADDRESSES
        address hubCoreRegistry = 0x0FAEeCEab0BCb63bE2Fe984Ea8c77778989d53eA;
        FlashloanProviders memory flProviders = FlashloanProviders({
            balancerV2Pool: 0xBA12222222228d8Ba445958a75a0704d566BF2C8,
            balancerV3Pool: 0xbA1333333333a1BA1108E8412f11850A5C319bA9,
            morphoPool: 0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb,
            dssFlash: 0x60744434d6339a6B27d73d9Eda62b6F66a0a04FA,
            aaveV3AddressProvider: 0x2f39d218133AFaB8F2B819B1066c7E434Ad94E9e,
            dai: 0x6B175474E89094C44Da98b954EedeAC495271d0F
        });
        HubPeriphery memory hubPeriphery = HubPeriphery({
            flashloanAggregator: address(0), // not used here
            hubPeripheryRegistry: 0xc0109106a2E119087a5739c9532ec7e1B039EE05,
            hubPeripheryFactory: 0xd6aeeEBCCC245dAa4146F54B75686C33C96c30dA,
            directDepositorBeacon: 0x20C61516dA97188a3B6f3856ff91B92A22dFB776,
            asyncRedeemerBeacon: 0x1f20CDfa19b860f0dD78FeFBb052be5aa5003dD9,
            watermarkFeeManagerBeacon: 0x8Eb36d96Ef39150fB00911415C7a136106793590,
            securityModuleBeacon: 0x49eE9b4865CBbF9ec8B142cdd4A5a65971F92542,
            metaMorphoOracleFactory: 0xA793e9548337654237BFa49fFD2188236d02e6A7,
            machineShareOracleBeacon: 0x9CcE24310C1c9c118449112e294C0C2068D96b9f,
            machineShareOracleFactory: 0x58DE6381cBCc919D72e6A2507cAe74925E69Daf5
        });

        // set to address(0) if upgrade-permissioned address is not a TimelockController instance.
        address proxyUpgradeTimelock = 0xa113bE73B97753A81A63d2539809b90451F1EC56;

        // DEPLOY NEW IMPLEMS
        HubPeripheryImplems memory hubPeripheryImplems;

        address caliberFactory = ICoreRegistry(hubCoreRegistry).coreFactory();
        hubPeripheryImplems.flashloanAggregator = _deployCode(
            abi.encodePacked(
                type(FlashloanAggregator).creationCode,
                abi.encode(
                    caliberFactory,
                    flProviders.balancerV2Pool,
                    flProviders.balancerV3Pool,
                    flProviders.morphoPool,
                    flProviders.dssFlash,
                    flProviders.aaveV3AddressProvider,
                    flProviders.dai
                )
            ),
            0
        );
        console.log("FlashloanAggregator:", hubPeripheryImplems.flashloanAggregator);

        hubPeripheryImplems.hubPeripheryRegistry =
            _deployCode(abi.encodePacked(type(HubPeripheryRegistry).creationCode), 0);
        console.log("HubPeripheryRegistry implem:", hubPeripheryImplems.hubPeripheryRegistry);

        hubPeripheryImplems.hubPeripheryFactory = _deployCode(
            abi.encodePacked(type(HubPeripheryFactory).creationCode, abi.encode(hubPeriphery.hubPeripheryRegistry)), 0
        );
        console.log("HubPeripheryFactory implem:", hubPeripheryImplems.hubPeripheryFactory);

        hubPeripheryImplems.directDepositor = _deployCode(
            abi.encodePacked(type(DirectDepositor).creationCode, abi.encode(hubPeriphery.hubPeripheryRegistry)), 0
        );
        console.log("DirectDepositor implem:", hubPeripheryImplems.directDepositor);

        hubPeripheryImplems.asyncRedeemer = _deployCode(
            abi.encodePacked(type(AsyncRedeemer).creationCode, abi.encode(hubPeriphery.hubPeripheryRegistry)), 0
        );
        console.log("AsyncRedeemer implem:", hubPeripheryImplems.asyncRedeemer);

        hubPeripheryImplems.watermarkFeeManager = _deployCode(
            abi.encodePacked(type(WatermarkFeeManager).creationCode, abi.encode(hubPeriphery.hubPeripheryRegistry)), 0
        );
        console.log("WatermarkFeeManager implem:", hubPeripheryImplems.watermarkFeeManager);

        hubPeripheryImplems.securityModule = _deployCode(
            abi.encodePacked(type(SecurityModule).creationCode, abi.encode(hubPeriphery.hubPeripheryRegistry)), 0
        );
        console.log("SecurityModule implem:", hubPeripheryImplems.securityModule);

        hubPeripheryImplems.metaMorphoOracleFactory =
            _deployCode(abi.encodePacked(type(MetaMorphoOracleFactory).creationCode), 0);
        console.log("MetaMorphoOracleFactory implem:", hubPeripheryImplems.metaMorphoOracleFactory);

        hubPeripheryImplems.machineShareOracle = _deployCode(
            abi.encodePacked(type(MachineShareOracle).creationCode, abi.encode(hubCoreRegistry)), 0
        );
        console.log("MachineShareOracle implem:", hubPeripheryImplems.machineShareOracle);

        hubPeripheryImplems.machineShareOracleFactory =
            _deployCode(abi.encodePacked(type(MachineShareOracleFactory).creationCode), 0);
        console.log("MachineShareOracleFactory implem:", hubPeripheryImplems.machineShareOracleFactory);

        // UPGRADE PROXIES AND BEACONS

        console.log("\n", "== Upgrade HubPeripheryRegistry ==");
        _upgradeTransparentProxy(
            hubPeriphery.hubPeripheryRegistry, hubPeripheryImplems.hubPeripheryRegistry, true, proxyUpgradeTimelock
        );

        console.log("\n", "== Upgrade HubPeripheryFactory ==");
        _upgradeTransparentProxy(
            address(hubPeriphery.hubPeripheryFactory),
            hubPeripheryImplems.hubPeripheryFactory,
            true,
            proxyUpgradeTimelock
        );

        console.log("\n", "== Upgrade DirectDepositor Beacon ==");
        _upgradeBeaconProxy(
            address(hubPeriphery.directDepositorBeacon), hubPeripheryImplems.directDepositor, true, proxyUpgradeTimelock
        );

        console.log("\n", "== Upgrade AsyncRedeemer Beacon ==");
        _upgradeBeaconProxy(
            address(hubPeriphery.asyncRedeemerBeacon), hubPeripheryImplems.asyncRedeemer, true, proxyUpgradeTimelock
        );

        console.log("\n", "== Upgrade WatermarkFeeManager Beacon ==");
        _upgradeBeaconProxy(
            address(hubPeriphery.watermarkFeeManagerBeacon),
            hubPeripheryImplems.watermarkFeeManager,
            true,
            proxyUpgradeTimelock
        );

        console.log("\n", "== Upgrade SecurityModule Beacon ==");
        _upgradeBeaconProxy(
            address(hubPeriphery.securityModuleBeacon), hubPeripheryImplems.securityModule, true, proxyUpgradeTimelock
        );

        console.log("\n", "== Upgrade MachineShareOracle Beacon ==");
        _upgradeBeaconProxy(
            address(hubPeriphery.machineShareOracleBeacon),
            hubPeripheryImplems.machineShareOracle,
            true,
            proxyUpgradeTimelock
        );

        console.log("\n", "== Upgrade MachineShareOracleFactory ==");
        _upgradeTransparentProxy(
            address(hubPeriphery.machineShareOracleFactory),
            hubPeripheryImplems.machineShareOracleFactory,
            true,
            proxyUpgradeTimelock
        );

        console.log("\n", "== Upgrade MetaMorphoOracleFactory ==");
        _upgradeTransparentProxy(
            address(hubPeriphery.metaMorphoOracleFactory),
            hubPeripheryImplems.metaMorphoOracleFactory,
            true,
            proxyUpgradeTimelock
        );

        // Set new FlashloanAggregator implem in HubCoreRegistry
        console.log("\n", "== Update FlashloanAggregator in CoreRegistry:", hubCoreRegistry);
        bytes memory cd = abi.encodeCall(ICoreRegistry.setFlashLoanModule, (hubPeripheryImplems.flashloanAggregator));
        console.log("Core Registry:", hubCoreRegistry);
        console.logBytes(cd);

        // AM updates for each new function + those which sig was modified
        // if (!vm.envOr("SKIP_AM_SETUP", false)) {
        //     setupHubPeripheryAMFunctionRoles(_core);
        // }
    }
}
