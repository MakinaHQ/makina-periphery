// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {stdJson} from "forge-std/StdJson.sol";
import {stdStorage, StdStorage} from "forge-std/StdStorage.sol";

import {ChainsInfo} from "@makina-core-test/utils/ChainsInfo.sol";

import {FlashloanAggregator} from "src/flashloans/FlashloanAggregator.sol";
import {AsyncRedeemer} from "src/redeemers/AsyncRedeemer.sol";
import {AsyncRedeemerFee} from "src/redeemers/AsyncRedeemerFee.sol";
import {DirectDepositor} from "src/depositors/DirectDepositor.sol";
import {SecurityModule} from "src/security-module/SecurityModule.sol";
import {WatermarkFeeManager} from "src/fee-managers/WatermarkFeeManager.sol";

import {DeployHubPeriphery} from "script/deployments/DeployHubPeriphery.s.sol";
import {DeploySpokePeriphery} from "script/deployments/DeploySpokePeriphery.s.sol";
import {DeploySecurityModule} from "script/deployments/DeploySecurityModule.s.sol";
import {DeployDirectDepositor} from "script/deployments/DeployDirectDepositor.s.sol";
import {DeployAsyncRedeemer} from "script/deployments/DeployAsyncRedeemer.s.sol";
import {DeployAsyncRedeemerFee} from "script/deployments/DeployAsyncRedeemerFee.s.sol";
import {DeployWatermarkFeeManager} from "script/deployments/DeployWatermarkFeeManager.s.sol";
import {SetupHubPeripheryRegistry} from "script/deployments/SetupHubPeripheryRegistry.s.sol";

import {Base_Test} from "../base/Base.t.sol";

contract Deploy_Scripts_Test is Base_Test {
    using stdJson for string;
    using stdStorage for StdStorage;

    // Scripts to test
    DeployHubPeriphery public deployHubPeriphery;
    SetupHubPeripheryRegistry public setupHubPeripheryRegistry;
    DeploySecurityModule public deploySecurityModule;
    DeployDirectDepositor public deployDirectDepositor;
    DeployAsyncRedeemer public deployAsyncRedeemer;
    DeployAsyncRedeemerFee public deployAsyncRedeemerFee;
    DeployWatermarkFeeManager public deployWatermarkFeeManager;

    DeploySpokePeriphery public deploySpokePeriphery;

    function setUp() public override {
        vm.setEnv("TEST_ENV", "true");

        ChainsInfo.ChainInfo memory chainInfo = ChainsInfo.getChainInfo(ChainsInfo.CHAIN_ID_ETHEREUM);
        vm.setEnv("HUB_PERIPHERY_INPUT_FILENAME", chainInfo.constantsFilename);
        vm.setEnv("HUB_PERIPHERY_OUTPUT_FILENAME", chainInfo.constantsFilename);

        vm.setEnv("HUB_STRAT_INPUT_FILENAME", chainInfo.constantsFilename);
        vm.setEnv("HUB_STRAT_OUTPUT_FILENAME", chainInfo.constantsFilename);

        chainInfo = ChainsInfo.getChainInfo(ChainsInfo.CHAIN_ID_BASE);
        vm.setEnv("SPOKE_PERIPHERY_INPUT_FILENAME", chainInfo.constantsFilename);
        vm.setEnv("SPOKE_PERIPHERY_OUTPUT_FILENAME", chainInfo.constantsFilename);

        // In provided access manager test instance, admin has permissions for setup below
        address admin = 0xae7f67EE9B8c465ACE4a1ec1138FaA483d93691A;
        vm.setEnv("TEST_SENDER", vm.toString(admin));
    }

    function test_LoadedState() public {
        deployHubPeriphery = new DeployHubPeriphery();
        deploySpokePeriphery = new DeploySpokePeriphery();

        address hubCoreRegistry = vm.parseJsonAddress(deployHubPeriphery.inputJson(), ".hubCoreRegistry");
        assertTrue(hubCoreRegistry != address(0));

        address aaveV3AddressProvider =
            vm.parseJsonAddress(deploySpokePeriphery.inputJson(), ".flashloanProviders.aaveV3AddressProvider");
        assertTrue(aaveV3AddressProvider != address(0));
    }

    function testScript_DeployHubPeriphery() public {
        vm.createSelectFork({urlOrAlias: ChainsInfo.getChainInfo(ChainsInfo.CHAIN_ID_ETHEREUM).foundryAlias});

        // Periphery deployment
        deployHubPeriphery = new DeployHubPeriphery();
        deployHubPeriphery.run();

        // In provided access manager test instance, admin has permissions for setup below
        address admin = 0xae7f67EE9B8c465ACE4a1ec1138FaA483d93691A;
        vm.setEnv("TEST_SENDER", vm.toString(admin));

        setupHubPeripheryRegistry = new SetupHubPeripheryRegistry();
        setupHubPeripheryRegistry.run();

        (HubPeriphery memory hubPeripheryDeployment) = deployHubPeriphery.deployment();

        // Check that FlashloanAggregator is correctly set up
        FlashloanProviders memory flProviders =
            parseFlashloanProviders(deployHubPeriphery.inputJson(), ".flashloanProviders");
        assertEq(address(hubPeripheryDeployment.flashloanAggregator.balancerV2Pool()), flProviders.balancerV2Pool);
        assertEq(address(hubPeripheryDeployment.flashloanAggregator.balancerV3Pool()), flProviders.balancerV3Pool);
        assertEq(address(hubPeripheryDeployment.flashloanAggregator.morphoPool()), flProviders.morphoPool);
        assertEq(address(hubPeripheryDeployment.flashloanAggregator.dssFlash()), flProviders.dssFlash);
        assertEq(
            address(hubPeripheryDeployment.flashloanAggregator.aaveV3AddressProvider()),
            flProviders.aaveV3AddressProvider
        );
        assertEq(address(hubPeripheryDeployment.flashloanAggregator.dai()), flProviders.dai);

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
            hubPeripheryDeployment.hubPeripheryRegistry
                .depositorBeacon(
                    uint16(vm.parseJsonUint(setupHubPeripheryRegistry.inputJson(), ".directDepositorImplemId"))
                )
        );
        assertEq(
            address(hubPeripheryDeployment.asyncRedeemerBeacon),
            hubPeripheryDeployment.hubPeripheryRegistry
                .redeemerBeacon(
                    uint16(vm.parseJsonUint(setupHubPeripheryRegistry.inputJson(), ".asyncRedeemerImplemId"))
                )
        );
        assertEq(
            address(hubPeripheryDeployment.watermarkFeeManagerBeacon),
            hubPeripheryDeployment.hubPeripheryRegistry
                .feeManagerBeacon(
                    uint16(vm.parseJsonUint(setupHubPeripheryRegistry.inputJson(), ".watermarkFeeManagerImplemId"))
                )
        );
    }

    function testScript_DeploySpokePeriphery() public {
        vm.createSelectFork({urlOrAlias: ChainsInfo.getChainInfo(ChainsInfo.CHAIN_ID_BASE).foundryAlias});

        // Periphery deployment
        deploySpokePeriphery = new DeploySpokePeriphery();
        deploySpokePeriphery.run();

        FlashloanAggregator deployment = deploySpokePeriphery.deployment();

        // Check that FlashloanAggregator is correctly set up
        FlashloanProviders memory flProviders =
            parseFlashloanProviders(deploySpokePeriphery.inputJson(), ".flashloanProviders");
        assertEq(address(deployment.balancerV2Pool()), flProviders.balancerV2Pool);
        assertEq(address(deployment.balancerV3Pool()), flProviders.balancerV3Pool);
        assertEq(address(deployment.morphoPool()), flProviders.morphoPool);
        assertEq(address(deployment.dssFlash()), flProviders.dssFlash);
        assertEq(address(deployment.aaveV3AddressProvider()), flProviders.aaveV3AddressProvider);
        assertEq(address(deployment.dai()), flProviders.dai);
    }

    function testScript_DeploySecurityModule() public {
        vm.createSelectFork({urlOrAlias: ChainsInfo.getChainInfo(ChainsInfo.CHAIN_ID_ETHEREUM).foundryAlias});

        HubPeriphery memory hubPeripheryDeployment = _deployHubPeriphery();

        // Depositor deployment
        deploySecurityModule = new DeploySecurityModule();
        deploySecurityModule.run();

        SecurityModule securityModule = SecurityModule(deploySecurityModule.deployedInstance());
        assertTrue(hubPeripheryDeployment.hubPeripheryFactory.isSecurityModule(address(securityModule)));
        assertEq(securityModule.machineShare(), vm.parseJsonAddress(deploySecurityModule.inputJson(), ".machineShare"));
        assertEq(
            securityModule.cooldownDuration(),
            vm.parseJsonUint(deploySecurityModule.inputJson(), ".initialCooldownDuration")
        );
        assertEq(
            securityModule.maxSlashableBps(),
            vm.parseJsonUint(deploySecurityModule.inputJson(), ".initialMaxSlashableBps")
        );
        assertEq(
            securityModule.minBalanceAfterSlash(),
            vm.parseJsonUint(deploySecurityModule.inputJson(), ".initialMinBalanceAfterSlash")
        );
    }

    function testScript_DeployDirectDepositor() public {
        vm.createSelectFork({urlOrAlias: ChainsInfo.getChainInfo(ChainsInfo.CHAIN_ID_ETHEREUM).foundryAlias});

        HubPeriphery memory hubPeripheryDeployment = _deployHubPeriphery();

        // Depositor deployment
        deployDirectDepositor = new DeployDirectDepositor();
        deployDirectDepositor.run();

        DirectDepositor directDepositor = DirectDepositor(deployDirectDepositor.deployedInstance());
        assertTrue(hubPeripheryDeployment.hubPeripheryFactory.isDepositor(address(directDepositor)));
        assertEq(
            directDepositor.isWhitelistEnabled(),
            vm.parseJsonBool(deployDirectDepositor.inputJson(), ".whitelistStatus")
        );
    }

    function testScript_AsyncRedeemer() public {
        vm.createSelectFork({urlOrAlias: ChainsInfo.getChainInfo(ChainsInfo.CHAIN_ID_ETHEREUM).foundryAlias});

        HubPeriphery memory hubPeripheryDeployment = _deployHubPeriphery();

        // Redeemer deployment
        deployAsyncRedeemer = new DeployAsyncRedeemer();
        deployAsyncRedeemer.run();

        AsyncRedeemer asyncRedeemer = AsyncRedeemer(deployAsyncRedeemer.deployedInstance());
        assertTrue(hubPeripheryDeployment.hubPeripheryFactory.isRedeemer(address(asyncRedeemer)));
        assertEq(
            asyncRedeemer.finalizationDelay(), vm.parseJsonUint(deployAsyncRedeemer.inputJson(), ".finalizationDelay")
        );
        assertEq(asyncRedeemer.minRedeemAmount(), vm.parseJsonUint(deployAsyncRedeemer.inputJson(), ".minRedeemAmount"));
        assertEq(
            asyncRedeemer.isWhitelistEnabled(), vm.parseJsonBool(deployAsyncRedeemer.inputJson(), ".whitelistStatus")
        );
    }

    function testScript_AsyncRedeemerFee() public {
        vm.createSelectFork({urlOrAlias: ChainsInfo.getChainInfo(ChainsInfo.CHAIN_ID_ETHEREUM).foundryAlias});

        HubPeriphery memory hubPeripheryDeployment = _deployHubPeriphery();

        // Redeemer deployment
        deployAsyncRedeemerFee = new DeployAsyncRedeemerFee();
        deployAsyncRedeemerFee.run();

        AsyncRedeemerFee asyncRedeemerFee = AsyncRedeemerFee(deployAsyncRedeemerFee.deployedInstance());
        assertTrue(hubPeripheryDeployment.hubPeripheryFactory.isRedeemer(address(asyncRedeemerFee)));
        assertEq(
            asyncRedeemerFee.finalizationDelay(),
            vm.parseJsonUint(deployAsyncRedeemerFee.inputJson(), ".finalizationDelay")
        );
        assertEq(
            asyncRedeemerFee.minRedeemAmount(), vm.parseJsonUint(deployAsyncRedeemerFee.inputJson(), ".minRedeemAmount")
        );
        assertEq(
            asyncRedeemerFee.isWhitelistEnabled(),
            vm.parseJsonBool(deployAsyncRedeemerFee.inputJson(), ".whitelistStatus")
        );
        assertEq(
            asyncRedeemerFee.redeemFeeRate(), vm.parseJsonUint(deployAsyncRedeemerFee.inputJson(), ".redeemFeeRate")
        );
        assertEq(
            asyncRedeemerFee.maxRedeemFeeRate(),
            vm.parseJsonUint(deployAsyncRedeemerFee.inputJson(), ".maxRedeemFeeRate")
        );
    }

    function testScript_WatermarkFeeManager() public {
        vm.createSelectFork({urlOrAlias: ChainsInfo.getChainInfo(ChainsInfo.CHAIN_ID_ETHEREUM).foundryAlias});

        HubPeriphery memory hubPeripheryDeployment = _deployHubPeriphery();

        // FeeManager deployment
        deployWatermarkFeeManager = new DeployWatermarkFeeManager();
        deployWatermarkFeeManager.run();

        WatermarkFeeManager watermarkFeeManager = WatermarkFeeManager(deployWatermarkFeeManager.deployedInstance());
        assertTrue(hubPeripheryDeployment.hubPeripheryFactory.isFeeManager(address(watermarkFeeManager)));
        assertEq(
            watermarkFeeManager.mgmtFeeRatePerSecond(),
            vm.parseJsonUint(
                deployWatermarkFeeManager.inputJson(), ".watermarkFeeManagerInitParams.initialMgmtFeeRatePerSecond"
            )
        );
        assertEq(
            watermarkFeeManager.smFeeRatePerSecond(),
            vm.parseJsonUint(
                deployWatermarkFeeManager.inputJson(), ".watermarkFeeManagerInitParams.initialSmFeeRatePerSecond"
            )
        );
        assertEq(
            watermarkFeeManager.perfFeeRate(),
            vm.parseJsonUint(deployWatermarkFeeManager.inputJson(), ".watermarkFeeManagerInitParams.initialPerfFeeRate")
        );

        uint256[] memory splitBps = vm.parseJsonUintArray(
            deployWatermarkFeeManager.inputJson(), ".watermarkFeeManagerInitParams.initialMgmtFeeSplitBps"
        );
        assertEq(watermarkFeeManager.mgmtFeeSplitBps().length, splitBps.length);
        for (uint256 i; i < splitBps.length; ++i) {
            assertEq(watermarkFeeManager.mgmtFeeSplitBps()[i], splitBps[i]);
        }

        address[] memory feeReceivers = vm.parseJsonAddressArray(
            deployWatermarkFeeManager.inputJson(), ".watermarkFeeManagerInitParams.initialMgmtFeeReceivers"
        );
        assertEq(watermarkFeeManager.mgmtFeeReceivers().length, feeReceivers.length);
        for (uint256 i; i < feeReceivers.length; ++i) {
            assertEq(watermarkFeeManager.mgmtFeeReceivers()[i], feeReceivers[i]);
        }

        splitBps = vm.parseJsonUintArray(
            deployWatermarkFeeManager.inputJson(), ".watermarkFeeManagerInitParams.initialPerfFeeSplitBps"
        );
        assertEq(watermarkFeeManager.perfFeeSplitBps().length, splitBps.length);
        for (uint256 i; i < splitBps.length; ++i) {
            assertEq(watermarkFeeManager.perfFeeSplitBps()[i], splitBps[i]);
        }

        feeReceivers = vm.parseJsonAddressArray(
            deployWatermarkFeeManager.inputJson(), ".watermarkFeeManagerInitParams.initialPerfFeeReceivers"
        );
        assertEq(watermarkFeeManager.perfFeeReceivers().length, feeReceivers.length);
        for (uint256 i; i < feeReceivers.length; ++i) {
            assertEq(watermarkFeeManager.perfFeeReceivers()[i], feeReceivers[i]);
        }
    }

    function _deployHubPeriphery() internal returns (HubPeriphery memory hubPeripheryDeployment) {
        // Periphery deployment
        deployHubPeriphery = new DeployHubPeriphery();
        deployHubPeriphery.run();

        // In provided access manager test instance, admin has permissions for setup below
        address admin = 0xae7f67EE9B8c465ACE4a1ec1138FaA483d93691A;
        vm.setEnv("TEST_SENDER", vm.toString(admin));

        vm.prank(admin);

        setupHubPeripheryRegistry = new SetupHubPeripheryRegistry();
        setupHubPeripheryRegistry.run();

        return deployHubPeriphery.deployment();
    }
}
