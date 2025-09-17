// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {stdJson} from "forge-std/StdJson.sol";
import {stdStorage, StdStorage} from "forge-std/StdStorage.sol";

import {ChainsInfo} from "@makina-core-test/utils/ChainsInfo.sol";

import {FlashloanAggregator} from "src/flashloans/FlashloanAggregator.sol";
import {AsyncRedeemer} from "src/redeemers/AsyncRedeemer.sol";
import {DirectDepositor} from "src/depositors/DirectDepositor.sol";
import {SecurityModule} from "src/security-module/SecurityModule.sol";
import {WatermarkFeeManager} from "src/fee-managers/WatermarkFeeManager.sol";

import {DeployHubPeriphery} from "script/deployments/DeployHubPeriphery.s.sol";
import {DeploySpokePeriphery} from "script/deployments/DeploySpokePeriphery.s.sol";
import {DeploySecurityModule} from "script/deployments/DeploySecurityModule.s.sol";
import {DeployDirectDepositor} from "script/deployments/DeployDirectDepositor.s.sol";
import {DeployAsyncRedeemer} from "script/deployments/DeployAsyncRedeemer.s.sol";
import {DeployWatermarkFeeManager} from "script/deployments/DeployWatermarkFeeManager.s.sol";
import {SetupHubPeripheryAM} from "script/deployments/SetupHubPeripheryAM.s.sol";
import {SetupHubPeripheryRegistry} from "script/deployments/SetupHubPeripheryRegistry.s.sol";
import {SortedParams} from "script/deployments/utils/SortedParams.sol";

import {Base_Test} from "../base/Base.t.sol";

contract Deploy_Scripts_Test is Base_Test {
    using stdJson for string;
    using stdStorage for StdStorage;

    // Scripts to test
    DeployHubPeriphery public deployHubPeriphery;
    SetupHubPeripheryAM public setupHubPeripheryAM;
    SetupHubPeripheryRegistry public setupHubPeripheryRegistry;
    DeploySecurityModule public deploySecurityModule;
    DeployDirectDepositor public deployDirectDepositor;
    DeployAsyncRedeemer public deployAsyncRedeemer;
    DeployWatermarkFeeManager public deployWatermarkFeeManager;

    DeploySpokePeriphery public deploySpokePeriphery;

    function test_LoadedState() public {
        ChainsInfo.ChainInfo memory chainInfo = ChainsInfo.getChainInfo(ChainsInfo.CHAIN_ID_ETHEREUM);

        vm.setEnv("HUB_INPUT_FILENAME", chainInfo.constantsFilename);
        vm.setEnv("HUB_OUTPUT_FILENAME", chainInfo.constantsFilename);

        chainInfo = ChainsInfo.getChainInfo(ChainsInfo.CHAIN_ID_BASE);
        vm.setEnv("SPOKE_INPUT_FILENAME", chainInfo.constantsFilename);
        vm.setEnv("SPOKE_OUTPUT_FILENAME", chainInfo.constantsFilename);

        vm.setEnv("SKIP_AM_SETUP", "true");

        deployHubPeriphery = new DeployHubPeriphery();
        deploySpokePeriphery = new DeploySpokePeriphery();

        address upgradeAdmin = abi.decode(vm.parseJson(deployHubPeriphery.inputJson(), ".upgradeAdmin"), (address));
        assertTrue(upgradeAdmin != address(0));

        address aaveV3AddressProvider = abi.decode(
            vm.parseJson(deploySpokePeriphery.inputJson(), ".flashloanProviders.aaveV3AddressProvider"), (address)
        );
        assertTrue(aaveV3AddressProvider != address(0));
    }

    function testScript_DeployHubPeriphery() public {
        ChainsInfo.ChainInfo memory chainInfo = ChainsInfo.getChainInfo(ChainsInfo.CHAIN_ID_ETHEREUM);
        vm.createSelectFork({urlOrAlias: chainInfo.foundryAlias});

        vm.setEnv("HUB_INPUT_FILENAME", chainInfo.constantsFilename);
        vm.setEnv("HUB_OUTPUT_FILENAME", chainInfo.constantsFilename);

        // Core deployment
        deployHubPeriphery = new DeployHubPeriphery();
        deployHubPeriphery.run();

        // In provided access manager test instance, upgradeAdmin also has permissions for setup below
        vm.setEnv(
            "TEST_SENDER",
            vm.toString(abi.decode(vm.parseJson(deployHubPeriphery.inputJson(), ".upgradeAdmin"), (address)))
        );

        setupHubPeripheryAM = new SetupHubPeripheryAM();
        setupHubPeripheryAM.run();

        setupHubPeripheryRegistry = new SetupHubPeripheryRegistry();
        setupHubPeripheryRegistry.run();

        (HubPeriphery memory hubPeripheryDeployment) = deployHubPeriphery.deployment();

        // Check that FlashloanAggregator is correctly set up
        SortedParams.FlashloanProvidersSorted memory flProviders = abi.decode(
            vm.parseJson(deployHubPeriphery.inputJson(), ".flashloanProviders"), (SortedParams.FlashloanProvidersSorted)
        );
        assertEq(
            address(hubPeripheryDeployment.flashloanAggregator.aaveV3AddressProvider()),
            flProviders.aaveV3AddressProvider
        );
        assertEq(address(hubPeripheryDeployment.flashloanAggregator.balancerV2Pool()), flProviders.balancerV2Pool);
        assertEq(address(hubPeripheryDeployment.flashloanAggregator.balancerV3Pool()), flProviders.balancerV3Pool);
        assertEq(address(hubPeripheryDeployment.flashloanAggregator.dai()), flProviders.dai);
        assertEq(address(hubPeripheryDeployment.flashloanAggregator.dssFlash()), flProviders.dssFlash);
        assertEq(address(hubPeripheryDeployment.flashloanAggregator.morphoPool()), flProviders.morphoPool);

        // Check that HubPeripheryRegistry is correctly set up
        assertEq(
            address(hubPeripheryDeployment.hubPeripheryFactory),
            hubPeripheryDeployment.hubPeripheryRegistry.peripheryFactory()
        );
        assertEq(
            address(hubPeripheryDeployment.securityModuleBeacon),
            hubPeripheryDeployment.hubPeripheryRegistry.securityModuleBeacon()
        );
        assertEq(
            address(hubPeripheryDeployment.directDepositorBeacon),
            hubPeripheryDeployment.hubPeripheryRegistry.depositorBeacon(
                abi.decode(vm.parseJson(setupHubPeripheryRegistry.inputJson(), ".directDepositorImplemId"), (uint16))
            )
        );
        assertEq(
            address(hubPeripheryDeployment.asyncRedeemerBeacon),
            hubPeripheryDeployment.hubPeripheryRegistry.redeemerBeacon(
                abi.decode(vm.parseJson(setupHubPeripheryRegistry.inputJson(), ".asyncRedeemerImplemId"), (uint16))
            )
        );
        assertEq(
            address(hubPeripheryDeployment.watermarkFeeManagerBeacon),
            hubPeripheryDeployment.hubPeripheryRegistry.feeManagerBeacon(
                abi.decode(
                    vm.parseJson(setupHubPeripheryRegistry.inputJson(), ".watermarkFeeManagerImplemId"), (uint16)
                )
            )
        );
    }

    function testScript_DeploySpokePeriphery() public {
        ChainsInfo.ChainInfo memory chainInfo = ChainsInfo.getChainInfo(ChainsInfo.CHAIN_ID_BASE);
        vm.createSelectFork({urlOrAlias: chainInfo.foundryAlias});

        vm.setEnv("SPOKE_INPUT_FILENAME", chainInfo.constantsFilename);
        vm.setEnv("SPOKE_OUTPUT_FILENAME", chainInfo.constantsFilename);
        vm.setEnv("SKIP_AM_SETUP", "true");

        // Core deployment
        deploySpokePeriphery = new DeploySpokePeriphery();
        deploySpokePeriphery.run();

        FlashloanAggregator deployment = deploySpokePeriphery.deployment();

        // Check that FlashloanAggregator is correctly set up
        SortedParams.FlashloanProvidersSorted memory flProviders = abi.decode(
            vm.parseJson(deploySpokePeriphery.inputJson(), ".flashloanProviders"),
            (SortedParams.FlashloanProvidersSorted)
        );
        assertEq(address(deployment.aaveV3AddressProvider()), flProviders.aaveV3AddressProvider);
        assertEq(address(deployment.balancerV2Pool()), flProviders.balancerV2Pool);
        assertEq(address(deployment.balancerV3Pool()), flProviders.balancerV3Pool);
        assertEq(address(deployment.dai()), flProviders.dai);
        assertEq(address(deployment.dssFlash()), flProviders.dssFlash);
        assertEq(address(deployment.morphoPool()), flProviders.morphoPool);
    }

    function testScript_DeploySecurityModule() public {
        HubPeriphery memory hubPeripheryDeployment = _deployHubPeriphery();

        // Depositor deployment
        deploySecurityModule = new DeploySecurityModule();
        deploySecurityModule.run();

        SecurityModule securityModule = SecurityModule(deploySecurityModule.deployedInstance());
        assertTrue(hubPeripheryDeployment.hubPeripheryFactory.isSecurityModule(address(securityModule)));
        assertEq(
            securityModule.machineShare(),
            abi.decode(vm.parseJson(deploySecurityModule.inputJson(), ".machineShare"), (address))
        );
        assertEq(
            securityModule.cooldownDuration(),
            abi.decode(vm.parseJson(deploySecurityModule.inputJson(), ".initialCooldownDuration"), (uint256))
        );
        assertEq(
            securityModule.maxSlashableBps(),
            abi.decode(vm.parseJson(deploySecurityModule.inputJson(), ".initialMaxSlashableBps"), (uint256))
        );
        assertEq(
            securityModule.minBalanceAfterSlash(),
            abi.decode(vm.parseJson(deploySecurityModule.inputJson(), ".initialMinBalanceAfterSlash"), (uint256))
        );
    }

    function testScript_DeployDirectDepositor() public {
        HubPeriphery memory hubPeripheryDeployment = _deployHubPeriphery();

        // Depositor deployment
        deployDirectDepositor = new DeployDirectDepositor();
        deployDirectDepositor.run();

        DirectDepositor directDepositor = DirectDepositor(deployDirectDepositor.deployedInstance());
        assertTrue(hubPeripheryDeployment.hubPeripheryFactory.isDepositor(address(directDepositor)));
        assertEq(
            directDepositor.isWhitelistEnabled(),
            abi.decode(vm.parseJson(deployDirectDepositor.inputJson(), ".whitelistStatus"), (bool))
        );
    }

    function testScript_AsyncRedeemer() public {
        HubPeriphery memory hubPeripheryDeployment = _deployHubPeriphery();

        // Redeemer deployment
        deployAsyncRedeemer = new DeployAsyncRedeemer();
        deployAsyncRedeemer.run();

        AsyncRedeemer asyncRedeemer = AsyncRedeemer(deployAsyncRedeemer.deployedInstance());
        assertTrue(hubPeripheryDeployment.hubPeripheryFactory.isRedeemer(address(asyncRedeemer)));
        assertEq(
            asyncRedeemer.finalizationDelay(),
            abi.decode(vm.parseJson(deployAsyncRedeemer.inputJson(), ".finalizationDelay"), (uint256))
        );
        assertEq(
            asyncRedeemer.isWhitelistEnabled(),
            abi.decode(vm.parseJson(deployAsyncRedeemer.inputJson(), ".whitelistStatus"), (bool))
        );
    }

    function testScript_WatermarkFeeManager() public {
        HubPeriphery memory hubPeripheryDeployment = _deployHubPeriphery();

        // FeeManager deployment
        deployWatermarkFeeManager = new DeployWatermarkFeeManager();
        deployWatermarkFeeManager.run();

        WatermarkFeeManager watermarkFeeManager = WatermarkFeeManager(deployWatermarkFeeManager.deployedInstance());
        assertTrue(hubPeripheryDeployment.hubPeripheryFactory.isFeeManager(address(watermarkFeeManager)));
        assertEq(
            watermarkFeeManager.mgmtFeeRatePerSecond(),
            abi.decode(
                vm.parseJson(
                    deployWatermarkFeeManager.inputJson(), ".watermarkFeeManagerInitParams.initialMgmtFeeRatePerSecond"
                ),
                (uint256)
            )
        );
        assertEq(
            watermarkFeeManager.smFeeRatePerSecond(),
            abi.decode(
                vm.parseJson(
                    deployWatermarkFeeManager.inputJson(), ".watermarkFeeManagerInitParams.initialSmFeeRatePerSecond"
                ),
                (uint256)
            )
        );
        assertEq(
            watermarkFeeManager.perfFeeRate(),
            abi.decode(
                vm.parseJson(deployWatermarkFeeManager.inputJson(), ".watermarkFeeManagerInitParams.initialPerfFeeRate"),
                (uint256)
            )
        );

        uint256[] memory splitBps = abi.decode(
            vm.parseJson(deployWatermarkFeeManager.inputJson(), ".watermarkFeeManagerInitParams.initialMgmtFeeSplitBps"),
            (uint256[])
        );
        assertEq(watermarkFeeManager.mgmtFeeSplitBps().length, splitBps.length);
        for (uint256 i; i < splitBps.length; i++) {
            assertEq(watermarkFeeManager.mgmtFeeSplitBps()[i], splitBps[i]);
        }

        address[] memory feeReceivers = abi.decode(
            vm.parseJson(
                deployWatermarkFeeManager.inputJson(), ".watermarkFeeManagerInitParams.initialMgmtFeeReceivers"
            ),
            (address[])
        );
        assertEq(watermarkFeeManager.mgmtFeeReceivers().length, feeReceivers.length);
        for (uint256 i; i < feeReceivers.length; i++) {
            assertEq(watermarkFeeManager.mgmtFeeReceivers()[i], feeReceivers[i]);
        }

        splitBps = abi.decode(
            vm.parseJson(deployWatermarkFeeManager.inputJson(), ".watermarkFeeManagerInitParams.initialPerfFeeSplitBps"),
            (uint256[])
        );
        assertEq(watermarkFeeManager.perfFeeSplitBps().length, splitBps.length);
        for (uint256 i; i < splitBps.length; i++) {
            assertEq(watermarkFeeManager.perfFeeSplitBps()[i], splitBps[i]);
        }

        feeReceivers = abi.decode(
            vm.parseJson(
                deployWatermarkFeeManager.inputJson(), ".watermarkFeeManagerInitParams.initialPerfFeeReceivers"
            ),
            (address[])
        );
        assertEq(watermarkFeeManager.perfFeeReceivers().length, feeReceivers.length);
        for (uint256 i; i < feeReceivers.length; i++) {
            assertEq(watermarkFeeManager.perfFeeReceivers()[i], feeReceivers[i]);
        }
    }

    function _deployHubPeriphery() internal returns (HubPeriphery memory hubPeripheryDeployment) {
        ChainsInfo.ChainInfo memory chainInfo = ChainsInfo.getChainInfo(ChainsInfo.CHAIN_ID_ETHEREUM);
        vm.createSelectFork({urlOrAlias: chainInfo.foundryAlias});

        vm.setEnv("HUB_INPUT_FILENAME", chainInfo.constantsFilename);
        vm.setEnv("HUB_OUTPUT_FILENAME", chainInfo.constantsFilename);
        vm.setEnv("SKIP_AM_SETUP", "true");

        // Core deployment
        deployHubPeriphery = new DeployHubPeriphery();
        deployHubPeriphery.run();

        // In provided access manager test instance, upgradeAdmin also has permissions for setup below
        vm.setEnv(
            "TEST_SENDER",
            vm.toString(abi.decode(vm.parseJson(deployHubPeriphery.inputJson(), ".upgradeAdmin"), (address)))
        );

        setupHubPeripheryAM = new SetupHubPeripheryAM();
        setupHubPeripheryAM.run();

        setupHubPeripheryRegistry = new SetupHubPeripheryRegistry();
        setupHubPeripheryRegistry.run();

        return deployHubPeriphery.deployment();
    }
}
