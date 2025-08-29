// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {stdJson} from "forge-std/StdJson.sol";
import {stdStorage, StdStorage} from "forge-std/StdStorage.sol";

import {ChainsInfo} from "@makina-core-test/utils/ChainsInfo.sol";

import {FlashloanAggregator} from "src/flashloans/FlashloanAggregator.sol";
import {AsyncRedeemer} from "src/redeemers/AsyncRedeemer.sol";
import {DirectDepositor} from "src/depositors/DirectDepositor.sol";
import {StakingModule} from "src/staking-module/StakingModule.sol";
import {WatermarkFeeManager} from "src/fee-managers/WatermarkFeeManager.sol";

import {DeployHubPeriphery} from "script/deployments/DeployHubPeriphery.s.sol";
import {DeploySpokePeriphery} from "script/deployments/DeploySpokePeriphery.s.sol";
import {DeployStakingModule} from "script/deployments/DeployStakingModule.s.sol";
import {DeployDirectDepositor} from "script/deployments/DeployDirectDepositor.s.sol";
import {DeployAsyncRedeemer} from "script/deployments/DeployAsyncRedeemer.s.sol";
import {DeployWatermarkFeeManager} from "script/deployments/DeployWatermarkFeeManager.s.sol";
import {SetupHubPeriphery} from "script/deployments/SetupHubPeriphery.s.sol";
import {SortedParams} from "script/deployments/utils/SortedParams.sol";

import {Base_Test} from "../base/Base.t.sol";

contract Deploy_Scripts_Test is Base_Test {
    using stdJson for string;
    using stdStorage for StdStorage;

    // Scripts to test
    DeployHubPeriphery public deployHubPeriphery;
    SetupHubPeriphery public setupHubPeriphery;
    DeployStakingModule public deployStakingModule;
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

        deployHubPeriphery = new DeployHubPeriphery();
        deploySpokePeriphery = new DeploySpokePeriphery();

        address hubDao = abi.decode(vm.parseJson(deployHubPeriphery.inputJson(), ".dao"), (address));
        assertTrue(hubDao != address(0));

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

        vm.setEnv(
            "TEST_SENDER", vm.toString(abi.decode(vm.parseJson(deployHubPeriphery.inputJson(), ".dao"), (address)))
        );

        setupHubPeriphery = new SetupHubPeriphery();
        setupHubPeriphery.run();

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
            address(hubPeripheryDeployment.stakingModuleBeacon),
            hubPeripheryDeployment.hubPeripheryRegistry.stakingModuleBeacon()
        );
        assertEq(
            address(hubPeripheryDeployment.directDepositorBeacon),
            hubPeripheryDeployment.hubPeripheryRegistry.depositorBeacon(
                abi.decode(vm.parseJson(setupHubPeriphery.inputJson(), ".directDepositorImplemId"), (uint16))
            )
        );
        assertEq(
            address(hubPeripheryDeployment.asyncRedeemerBeacon),
            hubPeripheryDeployment.hubPeripheryRegistry.redeemerBeacon(
                abi.decode(vm.parseJson(setupHubPeriphery.inputJson(), ".asyncRedeemerImplemId"), (uint16))
            )
        );
        assertEq(
            address(hubPeripheryDeployment.watermarkFeeManagerBeacon),
            hubPeripheryDeployment.hubPeripheryRegistry.feeManagerBeacon(
                abi.decode(vm.parseJson(setupHubPeriphery.inputJson(), ".watermarkFeeManagerImplemId"), (uint16))
            )
        );
    }

    function testScript_DeploySpokePeriphery() public {
        ChainsInfo.ChainInfo memory chainInfo = ChainsInfo.getChainInfo(ChainsInfo.CHAIN_ID_BASE);
        vm.createSelectFork({urlOrAlias: chainInfo.foundryAlias});

        vm.setEnv("SPOKE_INPUT_FILENAME", chainInfo.constantsFilename);
        vm.setEnv("SPOKE_OUTPUT_FILENAME", chainInfo.constantsFilename);

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

    function testScript_DeployStakingModule() public {
        HubPeriphery memory hubPeripheryDeployment = _deployHubPeriphery();

        // Depositor deployment
        deployStakingModule = new DeployStakingModule();
        deployStakingModule.run();

        StakingModule stakingModule = StakingModule(deployStakingModule.deployedInstance());
        assertTrue(hubPeripheryDeployment.hubPeripheryFactory.isStakingModule(address(stakingModule)));
        assertEq(
            stakingModule.machineShare(),
            abi.decode(vm.parseJson(deployStakingModule.inputJson(), ".machineShare"), (address))
        );
        assertEq(
            stakingModule.cooldownDuration(),
            abi.decode(vm.parseJson(deployStakingModule.inputJson(), ".initialCooldownDuration"), (uint256))
        );
        assertEq(
            stakingModule.maxSlashableBps(),
            abi.decode(vm.parseJson(deployStakingModule.inputJson(), ".initialMaxSlashableBps"), (uint256))
        );
        assertEq(
            stakingModule.minBalanceAfterSlash(),
            abi.decode(vm.parseJson(deployStakingModule.inputJson(), ".initialMinBalanceAfterSlash"), (uint256))
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

        // Core deployment
        deployHubPeriphery = new DeployHubPeriphery();
        deployHubPeriphery.run();

        vm.setEnv(
            "TEST_SENDER", vm.toString(abi.decode(vm.parseJson(deployHubPeriphery.inputJson(), ".dao"), (address)))
        );

        setupHubPeriphery = new SetupHubPeriphery();
        setupHubPeriphery.run();

        return deployHubPeriphery.deployment();
    }

    // function testScript_DeployPreDepositVault() public {
    //     ChainsInfo.ChainInfo memory chainInfo = ChainsInfo.getChainInfo(ChainsInfo.CHAIN_ID_ETHEREUM);
    //     vm.createSelectFork({urlOrAlias: chainInfo.foundryAlias});

    //     vm.setEnv("HUB_INPUT_FILENAME", chainInfo.constantsFilename);
    //     vm.setEnv("HUB_OUTPUT_FILENAME", chainInfo.constantsFilename);
    //     vm.setEnv("SKIP_AM_SETUP", "true");

    //     // Core deployment
    //     deployHubCore = new DeployHubCore();
    //     deployHubCore.run();

    //     (HubCore memory hubCoreDeployment,) = deployHubCore.deployment();

    //     // PreDeposit Vault deployment
    //     deployPreDepositVault = new DeployPreDepositVault();
    //     deployPreDepositVault.run();

    //     // Check that PreDepositVault is correctly set up
    //     SortedParams.PreDepositVaultInitParamsSorted memory pdvParams = abi.decode(
    //         vm.parseJson(deployPreDepositVault.inputJson(), ".preDepositVaultInitParams"),
    //         (SortedParams.PreDepositVaultInitParamsSorted)
    //     );
    //     address depositToken = abi.decode(vm.parseJson(deployPreDepositVault.inputJson(), ".depositToken"), (address));
    //     address accountingToken =
    //         abi.decode(vm.parseJson(deployPreDepositVault.inputJson(), ".accountingToken"), (address));
    //     string memory shareTokenName =
    //         abi.decode(vm.parseJson(deployPreDepositVault.inputJson(), ".shareTokenName"), (string));
    //     string memory shareTokenSymbol =
    //         abi.decode(vm.parseJson(deployPreDepositVault.inputJson(), ".shareTokenSymbol"), (string));

    //     IPreDepositVault preDepositVault = IPreDepositVault(deployPreDepositVault.deployedInstance());
    //     IMachineShare shareToken = IMachineShare(preDepositVault.shareToken());

    //     assertTrue(hubCoreDeployment.hubCoreFactory.isPreDepositVault(address(preDepositVault)));
    //     assertEq(preDepositVault.shareLimit(), pdvParams.initialShareLimit);
    //     assertEq(preDepositVault.whitelistMode(), pdvParams.initialWhitelistMode);
    //     assertEq(preDepositVault.riskManager(), pdvParams.initialRiskManager);
    //     assertEq(preDepositVault.depositToken(), depositToken);
    //     assertEq(preDepositVault.accountingToken(), accountingToken);
    //     assertEq(IAccessManaged(address(preDepositVault)).authority(), pdvParams.initialAuthority);

    //     assertEq(shareToken.name(), shareTokenName);
    //     assertEq(shareToken.symbol(), shareTokenSymbol);
    // }

    // function testScrip_DeployHubMachineFromPreDeposit() public {
    //     ChainsInfo.ChainInfo memory chainInfo = ChainsInfo.getChainInfo(ChainsInfo.CHAIN_ID_ETHEREUM);
    //     vm.createSelectFork({urlOrAlias: chainInfo.foundryAlias});

    //     vm.setEnv("HUB_INPUT_FILENAME", chainInfo.constantsFilename);
    //     vm.setEnv("HUB_OUTPUT_FILENAME", chainInfo.constantsFilename);
    //     vm.setEnv("SKIP_AM_SETUP", "true");

    //     // Core deployment
    //     deployHubCore = new DeployHubCore();
    //     deployHubCore.run();

    //     (HubCore memory hubCoreDeployment,) = deployHubCore.deployment();

    //     // PreDeposit Vault deployment
    //     deployPreDepositVault = new DeployPreDepositVault();
    //     deployPreDepositVault.run();

    //     // PreDeposit Vault migration to Machine
    //     deployMachineFromPreDeposit = new DeployHubMachineFromPreDeposit();
    //     stdstore.target(address(deployMachineFromPreDeposit)).sig("preDepositVault()").checked_write(
    //         deployPreDepositVault.deployedInstance()
    //     );
    //     deployMachineFromPreDeposit.run();

    //     // Check that Hub Machine is correctly set up
    //     SortedParams.MachineInitParamsSorted memory mParams = abi.decode(
    //         vm.parseJson(deployMachineFromPreDeposit.inputJson(), ".machineInitParams"),
    //         (SortedParams.MachineInitParamsSorted)
    //     );
    //     SortedParams.CaliberInitParamsSorted memory cParams = abi.decode(
    //         vm.parseJson(deployMachineFromPreDeposit.inputJson(), ".caliberInitParams"),
    //         (SortedParams.CaliberInitParamsSorted)
    //     );
    //     SortedParams.MakinaGovernableInitParamsSorted memory mgParams = abi.decode(
    //         vm.parseJson(deployMachineFromPreDeposit.inputJson(), ".makinaGovernableInitParams"),
    //         (SortedParams.MakinaGovernableInitParamsSorted)
    //     );
    //     address accountingToken =
    //         abi.decode(vm.parseJson(deployPreDepositVault.inputJson(), ".accountingToken"), (address));
    //     address depositToken = abi.decode(vm.parseJson(deployPreDepositVault.inputJson(), ".depositToken"), (address));
    //     string memory shareTokenName =
    //         abi.decode(vm.parseJson(deployPreDepositVault.inputJson(), ".shareTokenName"), (string));
    //     string memory shareTokenSymbol =
    //         abi.decode(vm.parseJson(deployPreDepositVault.inputJson(), ".shareTokenSymbol"), (string));

    //     IMachine machine = IMachine(deployMachineFromPreDeposit.deployedInstance());
    //     ICaliber hubCaliber = ICaliber(machine.hubCaliber());
    //     IMachineShare shareToken = IMachineShare(machine.shareToken());

    //     assertTrue(hubCoreDeployment.hubCoreFactory.isMachine(address(machine)));
    //     assertTrue(hubCoreDeployment.hubCoreFactory.isCaliber(address(hubCaliber)));
    //     assertEq(machine.depositor(), mParams.initialDepositor);
    //     assertEq(machine.redeemer(), mParams.initialRedeemer);
    //     assertEq(machine.accountingToken(), accountingToken);
    //     assertEq(machine.caliberStaleThreshold(), mParams.initialCaliberStaleThreshold);
    //     assertEq(machine.shareLimit(), mParams.initialShareLimit);
    //     assertEq(machine.accountingToken(), accountingToken);
    //     assertTrue(machine.isIdleToken(depositToken));

    //     assertEq(machine.mechanic(), mgParams.initialMechanic);
    //     assertEq(machine.securityCouncil(), mgParams.initialSecurityCouncil);
    //     assertEq(machine.riskManager(), mgParams.initialRiskManager);
    //     assertEq(machine.riskManagerTimelock(), mgParams.initialRiskManagerTimelock);
    //     assertEq(IAccessManaged(address(machine)).authority(), mgParams.initialAuthority);

    //     assertEq(hubCaliber.hubMachineEndpoint(), address(machine));
    //     assertEq(hubCaliber.accountingToken(), accountingToken);
    //     assertEq(hubCaliber.positionStaleThreshold(), cParams.initialPositionStaleThreshold);
    //     assertEq(hubCaliber.allowedInstrRoot(), cParams.initialAllowedInstrRoot);
    //     assertEq(hubCaliber.timelockDuration(), cParams.initialTimelockDuration);
    //     assertEq(hubCaliber.maxPositionIncreaseLossBps(), cParams.initialMaxPositionIncreaseLossBps);
    //     assertEq(hubCaliber.maxPositionDecreaseLossBps(), cParams.initialMaxPositionDecreaseLossBps);
    //     assertEq(hubCaliber.maxSwapLossBps(), cParams.initialMaxSwapLossBps);
    //     assertEq(hubCaliber.cooldownDuration(), cParams.initialCooldownDuration);

    //     assertEq(machine.getSpokeCalibersLength(), 0);
    //     assertEq(shareToken.name(), shareTokenName);
    //     assertEq(shareToken.symbol(), shareTokenSymbol);
    // }

    // function testScript_DeploySpokeCore() public {
    //     ChainsInfo.ChainInfo memory chainInfo = ChainsInfo.getChainInfo(ChainsInfo.CHAIN_ID_BASE);
    //     vm.createSelectFork({urlOrAlias: chainInfo.foundryAlias});

    //     vm.setEnv("SPOKE_INPUT_FILENAME", chainInfo.constantsFilename);
    //     vm.setEnv("SPOKE_OUTPUT_FILENAME", chainInfo.constantsFilename);
    //     vm.setEnv("SKIP_AM_SETUP", "true");

    //     // Spoke Core deployment
    //     deploySpokeCore = new DeploySpokeCore();
    //     deploySpokeCore.run();

    //     (SpokeCore memory spokeCoreDeployment, UpgradeableBeacon[] memory bridgeAdapterBeaconsDeployment) =
    //         deploySpokeCore.deployment();

    //     // Check that OracleRegistry is correctly set up
    //     PriceFeedRoute[] memory _priceFeedRoutes =
    //         abi.decode(vm.parseJson(deploySpokeCore.inputJson(), ".priceFeedRoutes"), (PriceFeedRoute[]));
    //     for (uint256 i; i < _priceFeedRoutes.length; i++) {
    //         (address feed1, address feed2) = spokeCoreDeployment.oracleRegistry.getFeedRoute(_priceFeedRoutes[i].token);
    //         assertEq(_priceFeedRoutes[i].feed1, feed1);
    //         assertEq(_priceFeedRoutes[i].feed2, feed2);
    //     }

    //     // Check that TokenRegistry is correctly set up
    //     TokenToRegister[] memory tokensToRegister =
    //         abi.decode(vm.parseJson(deploySpokeCore.inputJson(), ".foreignTokens"), (TokenToRegister[]));
    //     for (uint256 i; i < tokensToRegister.length; i++) {
    //         assertEq(
    //             spokeCoreDeployment.tokenRegistry.getForeignToken(
    //                 tokensToRegister[i].localToken, tokensToRegister[i].foreignEvmChainId
    //             ),
    //             tokensToRegister[i].foreignToken
    //         );
    //         assertEq(
    //             spokeCoreDeployment.tokenRegistry.getLocalToken(
    //                 tokensToRegister[i].foreignToken, tokensToRegister[i].foreignEvmChainId
    //             ),
    //             tokensToRegister[i].localToken
    //         );
    //     }

    //     // Check that SwapModule is correctly set up
    //     SwapperData[] memory _swappersData =
    //         abi.decode(vm.parseJson(deploySpokeCore.inputJson(), ".swappersTargets"), (SwapperData[]));
    //     for (uint256 i; i < _swappersData.length; i++) {
    //         (address approvalTarget, address executionTarget) =
    //             spokeCoreDeployment.swapModule.getSwapperTargets(_swappersData[i].swapperId);
    //         assertEq(_swappersData[i].approvalTarget, approvalTarget);
    //         assertEq(_swappersData[i].executionTarget, executionTarget);
    //     }

    //     // Check that BridgeAdapterBeacons are correctly set up
    //     BridgeData[] memory _bridgesData =
    //         abi.decode(vm.parseJson(deploySpokeCore.inputJson(), ".bridgesTargets"), (BridgeData[]));
    //     for (uint256 i; i < _bridgesData.length; i++) {
    //         IBridgeAdapter implementation = IBridgeAdapter(bridgeAdapterBeaconsDeployment[i].implementation());
    //         address approvalTarget = implementation.approvalTarget();
    //         address executionTarget = implementation.executionTarget();
    //         address receiveSource = implementation.receiveSource();
    //         assertEq(_bridgesData[i].approvalTarget, approvalTarget);
    //         assertEq(_bridgesData[i].executionTarget, executionTarget);
    //         assertEq(_bridgesData[i].receiveSource, receiveSource);
    //     }
    // }

    // function testScript_DeploySpokeCaliber() public {
    //     ChainsInfo.ChainInfo memory chainInfo = ChainsInfo.getChainInfo(ChainsInfo.CHAIN_ID_BASE);
    //     vm.createSelectFork({urlOrAlias: chainInfo.foundryAlias});

    //     vm.setEnv("SPOKE_INPUT_FILENAME", chainInfo.constantsFilename);
    //     vm.setEnv("SPOKE_OUTPUT_FILENAME", chainInfo.constantsFilename);
    //     vm.setEnv("SKIP_AM_SETUP", "true");

    //     // Spoke Core deployment
    //     deploySpokeCore = new DeploySpokeCore();
    //     deploySpokeCore.run();

    //     (SpokeCore memory spokeCoreDeployment,) = deploySpokeCore.deployment();

    //     // Caliber deployment
    //     deploySpokeCaliber = new DeploySpokeCaliber();
    //     deploySpokeCaliber.run();

    //     // Check that Spoke Caliber is correctly set up
    //     SortedParams.CaliberInitParamsSorted memory cParams = abi.decode(
    //         vm.parseJson(deploySpokeCaliber.inputJson(), ".caliberInitParams"), (SortedParams.CaliberInitParamsSorted)
    //     );
    //     SortedParams.MakinaGovernableInitParamsSorted memory mgParams = abi.decode(
    //         vm.parseJson(deploySpokeCaliber.inputJson(), ".makinaGovernableInitParams"),
    //         (SortedParams.MakinaGovernableInitParamsSorted)
    //     );
    //     address accountingToken =
    //         abi.decode(vm.parseJson(deploySpokeCaliber.inputJson(), ".accountingToken"), (address));
    //     ICaliber spokeCaliber = ICaliber(deploySpokeCaliber.deployedInstance());

    //     assertTrue(spokeCoreDeployment.spokeCoreFactory.isCaliber(address(spokeCaliber)));
    //     assertTrue(spokeCoreDeployment.spokeCoreFactory.isCaliberMailbox(spokeCaliber.hubMachineEndpoint()));

    //     assertEq(spokeCaliber.accountingToken(), accountingToken);
    //     assertEq(spokeCaliber.positionStaleThreshold(), cParams.initialPositionStaleThreshold);
    //     assertEq(spokeCaliber.allowedInstrRoot(), cParams.initialAllowedInstrRoot);
    //     assertEq(spokeCaliber.timelockDuration(), cParams.initialTimelockDuration);
    //     assertEq(spokeCaliber.maxPositionIncreaseLossBps(), cParams.initialMaxPositionIncreaseLossBps);
    //     assertEq(spokeCaliber.maxPositionDecreaseLossBps(), cParams.initialMaxPositionDecreaseLossBps);
    //     assertEq(spokeCaliber.maxSwapLossBps(), cParams.initialMaxSwapLossBps);
    //     assertEq(spokeCaliber.cooldownDuration(), cParams.initialCooldownDuration);

    //     ICaliberMailbox mailbox = ICaliberMailbox(spokeCaliber.hubMachineEndpoint());
    //     assertEq(ICaliberMailbox(mailbox).caliber(), address(spokeCaliber));

    //     assertEq(mailbox.mechanic(), mgParams.initialMechanic);
    //     assertEq(mailbox.securityCouncil(), mgParams.initialSecurityCouncil);
    //     assertEq(mailbox.riskManager(), mgParams.initialRiskManager);
    //     assertEq(mailbox.riskManagerTimelock(), mgParams.initialRiskManagerTimelock);
    //     assertEq(IAccessManaged(address(mailbox)).authority(), mgParams.initialAuthority);
    //     assertEq(IAccessManaged(address(spokeCaliber)).authority(), mgParams.initialAuthority);

    //     assertEq(spokeCaliber.getPositionsLength(), 0);
    //     assertEq(spokeCaliber.getBaseTokensLength(), 1);
    // }

    // function testScript_DeployTimelockController() public {
    //     ChainsInfo.ChainInfo memory chainInfo = ChainsInfo.getChainInfo(ChainsInfo.CHAIN_ID_ETHEREUM);
    //     vm.createSelectFork({urlOrAlias: chainInfo.foundryAlias});

    //     vm.setEnv("TIMELOCK_CONTROLLER_INPUT_FILENAME", chainInfo.constantsFilename);
    //     vm.setEnv("TIMELOCK_CONTROLLER_OUTPUT_FILENAME", chainInfo.constantsFilename);

    //     // Timelock Controller deployment
    //     deployTimelockController = new DeployTimelockController();
    //     deployTimelockController.run();

    //     // Check that Timelock Controller is correctly set up
    //     SortedParams.TimelockControllerInitParamsSorted memory tcParams = abi.decode(
    //         vm.parseJson(deployTimelockController.inputJson()), (SortedParams.TimelockControllerInitParamsSorted)
    //     );
    //     TimelockController timelockController = TimelockController(payable(deployTimelockController.deployedInstance()));
    //     for (uint256 i = 0; i < tcParams.initialProposers.length; i++) {
    //         assertTrue(timelockController.hasRole(timelockController.PROPOSER_ROLE(), tcParams.initialProposers[i]));
    //         assertTrue(timelockController.hasRole(timelockController.CANCELLER_ROLE(), tcParams.initialProposers[i]));
    //     }
    //     for (uint256 i = 0; i < tcParams.initialExecutors.length; i++) {
    //         assertTrue(timelockController.hasRole(timelockController.EXECUTOR_ROLE(), tcParams.initialExecutors[i]));
    //     }
    //     assertTrue(timelockController.hasRole(timelockController.DEFAULT_ADMIN_ROLE(), tcParams.initialAdmin));
    //     assertEq(timelockController.getMinDelay(), tcParams.initialMinDelay);
    // }
}
