// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";

import {IAccessManager} from "@openzeppelin/contracts/access/manager/IAccessManager.sol";
import {
    AccessManagerUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/manager/AccessManagerUpgradeable.sol";
import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";

import "@makina-core-test/utils/Constants.sol" as Core_Constants;
import {Roles} from "@makina-core/libraries/Roles.sol";

import {AsyncRedeemer} from "src/redeemers/AsyncRedeemer.sol";
import {AsyncRedeemerFee} from "src/redeemers/AsyncRedeemerFee.sol";
import {DirectDepositor} from "src/depositors/DirectDepositor.sol";
import {FlashloanAggregator} from "src/flashloans/FlashloanAggregator.sol";
import {IHubPeripheryFactory} from "src/interfaces/IHubPeripheryFactory.sol";
import {IHubPeripheryRegistry} from "src/interfaces/IHubPeripheryRegistry.sol";
import {SecurityModule} from "src/security-module/SecurityModule.sol";
import {WatermarkFeeManager} from "src/fee-managers/WatermarkFeeManager.sol";

import {DeployAsyncRedeemer} from "script/deployments/DeployAsyncRedeemer.s.sol";
import {DeployAsyncRedeemerFee} from "script/deployments/DeployAsyncRedeemerFee.s.sol";
import {DeployDirectDepositor} from "script/deployments/DeployDirectDepositor.s.sol";
import {DeployHubPeriphery} from "script/deployments/DeployHubPeriphery.s.sol";
import {DeploySecurityModule} from "script/deployments/DeploySecurityModule.s.sol";
import {DeploySpokePeriphery} from "script/deployments/DeploySpokePeriphery.s.sol";
import {DeployWatermarkFeeManager} from "script/deployments/DeployWatermarkFeeManager.s.sol";
import {SetupHubPeripheryAM} from "script/deployments/SetupHubPeripheryAM.s.sol";
import {SetupHubPeripheryRegistry} from "script/deployments/SetupHubPeripheryRegistry.s.sol";

import {Base} from "../base/Base.sol";

contract Deploy_Scripts_Test is Base, Test, Core_Constants.Constants {
    /// @dev Admin of the live Mainnet AccessManager the test hub periphery is bound to, see `_forkHubChain`.
    address internal constant LIVE_AM_ADMIN = 0xae7f67EE9B8c465ACE4a1ec1138FaA483d93691A;

    // Scripts to test
    DeployHubPeriphery public deployHubPeriphery;
    SetupHubPeripheryRegistry public setupHubPeripheryRegistry;
    SetupHubPeripheryAM public setupHubPeripheryAM;
    DeploySecurityModule public deploySecurityModule;
    DeployDirectDepositor public deployDirectDepositor;
    DeployAsyncRedeemer public deployAsyncRedeemer;
    DeployAsyncRedeemerFee public deployAsyncRedeemerFee;
    DeployWatermarkFeeManager public deployWatermarkFeeManager;

    DeploySpokePeriphery public deploySpokePeriphery;

    function test_LoadParamsFromEnv() public {
        string memory basePath = string.concat(vm.projectRoot(), "/script/deployments/");
        string memory hubFilename = _hubTestFilename();
        string memory spokeFilename = _spokeTestFilename();
        address peripheryFactory = vm.parseJsonAddress(
            vm.readFile(string.concat(basePath, "outputs/hub-peripheries/", hubFilename)), ".HubPeripheryFactory"
        );

        vm.setEnv("HUB_PERIPHERY_INPUT_FILENAME", hubFilename);
        vm.setEnv("HUB_PERIPHERY_OUTPUT_FILENAME", hubFilename);
        deployHubPeriphery = new DeployHubPeriphery();
        deployHubPeriphery.loadParamsFromEnv();

        assertEq(deployHubPeriphery.outputPath(), string.concat(basePath, "outputs/hub-peripheries/", hubFilename));
        assertTrue(vm.parseJsonAddress(deployHubPeriphery.inputJson(), ".hubCoreRegistry") != address(0));

        // The setup scripts read the deployed addresses from the hub periphery output file
        vm.setEnv("VIEW_MODE", "true");
        setupHubPeripheryRegistry = new SetupHubPeripheryRegistry();
        setupHubPeripheryRegistry.loadParamsFromEnv();

        assertTrue(setupHubPeripheryRegistry.viewMode());
        assertEq(vm.parseJsonAddress(setupHubPeripheryRegistry.outputJson(), ".HubPeripheryFactory"), peripheryFactory);
        assertEq(
            vm.parseJsonUint(setupHubPeripheryRegistry.implemIdsJson(), ".directDepositorImplemId"),
            _implemId(".directDepositorImplemId")
        );

        setupHubPeripheryAM = new SetupHubPeripheryAM();
        setupHubPeripheryAM.loadParamsFromEnv();

        assertTrue(setupHubPeripheryAM.viewMode());
        assertEq(vm.parseJsonAddress(setupHubPeripheryAM.outputJson(), ".HubPeripheryFactory"), peripheryFactory);
        assertTrue(vm.parseJsonAddress(setupHubPeripheryAM.inputJson(), ".accessManager") != address(0));

        // The instance scripts read the factory from the hub periphery output file, and their implementation id from
        // the implementation ids input file
        vm.setEnv("HUB_STRAT_INPUT_FILENAME", hubFilename);
        vm.setEnv("HUB_STRAT_OUTPUT_FILENAME", hubFilename);
        vm.setEnv("VIEW_MODE", "false");
        deploySecurityModule = new DeploySecurityModule();
        deploySecurityModule.loadParamsFromEnv();

        assertFalse(deploySecurityModule.viewMode());
        assertEq(deploySecurityModule.peripheryFactory(), peripheryFactory);
        assertEq(deploySecurityModule.outputPath(), string.concat(basePath, "outputs/security-modules/", hubFilename));
        assertTrue(vm.parseJsonAddress(deploySecurityModule.inputJson(), ".machineShare") != address(0));

        deployDirectDepositor = new DeployDirectDepositor();
        deployDirectDepositor.loadParamsFromEnv();

        assertEq(deployDirectDepositor.peripheryFactory(), peripheryFactory);
        assertEq(deployDirectDepositor.implemId(), _implemId(".directDepositorImplemId"));
        assertEq(
            deployDirectDepositor.outputPath(),
            string.concat(basePath, "outputs/depositors/direct-depositors/", hubFilename)
        );

        deployAsyncRedeemer = new DeployAsyncRedeemer();
        deployAsyncRedeemer.loadParamsFromEnv();

        assertEq(deployAsyncRedeemer.peripheryFactory(), peripheryFactory);
        assertEq(deployAsyncRedeemer.implemId(), _implemId(".asyncRedeemerImplemId"));
        assertEq(
            deployAsyncRedeemer.outputPath(), string.concat(basePath, "outputs/redeemers/async-redeemers/", hubFilename)
        );

        deployAsyncRedeemerFee = new DeployAsyncRedeemerFee();
        deployAsyncRedeemerFee.loadParamsFromEnv();

        assertEq(deployAsyncRedeemerFee.peripheryFactory(), peripheryFactory);
        assertEq(deployAsyncRedeemerFee.implemId(), _implemId(".asyncRedeemerFeeImplemId"));
        assertEq(
            deployAsyncRedeemerFee.outputPath(),
            string.concat(basePath, "outputs/redeemers/async-redeemer-fees/", hubFilename)
        );

        // In view mode, no output file is resolved
        vm.setEnv("VIEW_MODE", "true");
        deployWatermarkFeeManager = new DeployWatermarkFeeManager();
        deployWatermarkFeeManager.loadParamsFromEnv();

        assertTrue(deployWatermarkFeeManager.viewMode());
        assertEq(deployWatermarkFeeManager.peripheryFactory(), peripheryFactory);
        assertEq(deployWatermarkFeeManager.implemId(), _implemId(".watermarkFeeManagerImplemId"));
        assertEq(deployWatermarkFeeManager.outputPath(), "");

        vm.setEnv("SPOKE_PERIPHERY_INPUT_FILENAME", spokeFilename);
        vm.setEnv("SPOKE_PERIPHERY_OUTPUT_FILENAME", spokeFilename);
        deploySpokePeriphery = new DeploySpokePeriphery();
        deploySpokePeriphery.loadParamsFromEnv();

        assertEq(
            deploySpokePeriphery.outputPath(), string.concat(basePath, "outputs/spoke-peripheries/", spokeFilename)
        );
        assertTrue(
            vm.parseJsonAddress(deploySpokePeriphery.inputJson(), ".flashloanProviders.aaveV3AddressProvider")
                != address(0)
        );
    }

    function testScript_DeployHubPeriphery() public {
        _forkHubChain();

        // Periphery deployment, writing the output file, then registry setup
        HubPeriphery memory hubPeripheryDeployment = _deployHubPeriphery();
        _setupHubPeripheryRegistry();

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
        IHubPeripheryRegistry hubPeripheryRegistry = hubPeripheryDeployment.hubPeripheryRegistry;
        assertEq(address(hubPeripheryDeployment.hubPeripheryFactory), hubPeripheryRegistry.peripheryFactory());
        assertEq(address(hubPeripheryDeployment.securityModuleBeacon), hubPeripheryRegistry.securityModuleBeacon());
        assertEq(
            address(hubPeripheryDeployment.directDepositorBeacon),
            hubPeripheryRegistry.depositorBeacon(_implemId(".directDepositorImplemId"))
        );
        assertEq(
            address(hubPeripheryDeployment.asyncRedeemerBeacon),
            hubPeripheryRegistry.redeemerBeacon(_implemId(".asyncRedeemerImplemId"))
        );
        assertEq(
            address(hubPeripheryDeployment.asyncRedeemerFeeBeacon),
            hubPeripheryRegistry.redeemerBeacon(_implemId(".asyncRedeemerFeeImplemId"))
        );
        assertEq(
            address(hubPeripheryDeployment.watermarkFeeManagerBeacon),
            hubPeripheryRegistry.feeManagerBeacon(_implemId(".watermarkFeeManagerImplemId"))
        );

        // Check that the output file is written
        string memory outputJson = vm.readFile(deployHubPeriphery.outputPath());
        assertEq(
            vm.parseJsonAddress(outputJson, ".FlashloanAggregator"), address(hubPeripheryDeployment.flashloanAggregator)
        );
        assertEq(
            vm.parseJsonAddress(outputJson, ".HubPeripheryFactory"), address(hubPeripheryDeployment.hubPeripheryFactory)
        );
    }

    function testScript_DeployHubPeriphery_RevertWhen_AlreadyDeployed() public {
        _forkHubChain();

        HubPeriphery memory hubPeripheryDeployment = _deployHubPeriphery();

        // The FlashloanAggregator is the first CREATE3 deployment, so a second run from the same deployer fails there
        address occupied = address(hubPeripheryDeployment.flashloanAggregator);

        deployHubPeriphery = new DeployHubPeriphery();
        deployHubPeriphery.setFilenames(_hubTestFilename(), "");
        vm.expectRevert(
            bytes(string.concat("DeployPeriphery: CREATE3 target already has code: ", vm.toString(occupied)))
        );
        deployHubPeriphery.run();
    }

    function testScript_SetupHubPeripheryAM() public {
        _forkHubChain();

        HubPeriphery memory hubPeripheryDeployment = _deployHubPeriphery();

        setupHubPeripheryAM = new SetupHubPeripheryAM();
        setupHubPeripheryAM.setFilenames(_hubTestFilename(), _hubTestFilename());
        setupHubPeripheryAM.run();

        IAccessManager accessManager =
            IAccessManager(vm.parseJsonAddress(setupHubPeripheryAM.inputJson(), ".accessManager"));

        // Check that every listed function role is set
        AMFunctionRole[] memory functionRoles = hubPeripheryAMFunctionRoles(hubPeripheryDeployment);
        assertEq(setupHubPeripheryAM.callsLength(), functionRoles.length);
        for (uint256 i; i < functionRoles.length; ++i) {
            for (uint256 j; j < functionRoles[i].selectors.length; ++j) {
                assertEq(
                    accessManager.getTargetFunctionRole(functionRoles[i].target, functionRoles[i].selectors[j]),
                    functionRoles[i].roleId
                );
            }
        }

        // Spot checks of the roles the list is expected to hold
        assertEq(
            accessManager.getTargetFunctionRole(
                address(hubPeripheryDeployment.hubPeripheryRegistry), IHubPeripheryRegistry.setDepositorBeacon.selector
            ),
            Roles.INFRA_UPGRADE_ROLE
        );
        assertEq(
            accessManager.getTargetFunctionRole(
                address(hubPeripheryDeployment.hubPeripheryFactory), IHubPeripheryFactory.createDepositor.selector
            ),
            Roles.STRATEGY_DEPLOYMENT_ROLE
        );
        assertEq(
            accessManager.getTargetFunctionRole(
                address(hubPeripheryDeployment.directDepositorBeacon), UpgradeableBeacon.upgradeTo.selector
            ),
            Roles.INFRA_UPGRADE_ROLE
        );
    }

    function testScript_SetupHubPeripheryAM_ViewMode() public {
        _forkHubChain();

        HubPeriphery memory hubPeripheryDeployment = _deployHubPeriphery();

        // View mode: the calls are logged, the AccessManager is never called and no role is set
        setupHubPeripheryAM = new SetupHubPeripheryAM();
        setupHubPeripheryAM.setFilenames(_hubTestFilename(), _hubTestFilename());
        setupHubPeripheryAM.setViewMode(true);

        address accessManager = vm.parseJsonAddress(setupHubPeripheryAM.inputJson(), ".accessManager");
        vm.expectCall(accessManager, abi.encodeWithSelector(IAccessManager.setTargetFunctionRole.selector), 0);
        setupHubPeripheryAM.run();

        assertEq(setupHubPeripheryAM.callsLength(), hubPeripheryAMFunctionRoles(hubPeripheryDeployment).length);
        assertEq(
            IAccessManager(accessManager)
                .getTargetFunctionRole(
                    address(hubPeripheryDeployment.hubPeripheryRegistry),
                    IHubPeripheryRegistry.setPeripheryFactory.selector
                ),
            0
        );
    }

    function testScript_DeploySpokePeriphery() public {
        vm.createSelectFork({urlOrAlias: getChain(BASE_CHAIN_ID).chainAlias});

        // Periphery deployment, writing the output file
        deploySpokePeriphery = new DeploySpokePeriphery();
        deploySpokePeriphery.setFilenames(_spokeTestFilename(), _spokeTestFilename());
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

        // Check that the output file is written
        assertEq(
            vm.parseJsonAddress(vm.readFile(deploySpokePeriphery.outputPath()), ".FlashloanAggregator"),
            address(deployment)
        );
    }

    function testScript_DeploySecurityModule() public {
        _forkHubChain();

        HubPeriphery memory hubPeripheryDeployment = _deployAndSetupHubPeriphery();

        // Security module deployment
        deploySecurityModule = new DeploySecurityModule();
        deploySecurityModule.setParams(
            address(hubPeripheryDeployment.hubPeripheryFactory), _hubTestFilename(), _hubTestFilename()
        );
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

        // Check that the output file is written
        assertEq(
            vm.parseJsonAddress(vm.readFile(deploySecurityModule.outputPath()), ".SecurityModule"),
            address(securityModule)
        );
    }

    function testScript_DeploySecurityModule_ViewMode() public {
        _forkHubChain();

        HubPeriphery memory hubPeripheryDeployment = _deployAndSetupHubPeriphery();

        // View mode: the calldata is logged, the factory is never called and nothing is deployed
        deploySecurityModule = new DeploySecurityModule();
        deploySecurityModule.setParams(address(hubPeripheryDeployment.hubPeripheryFactory), _hubTestFilename(), "");
        deploySecurityModule.setViewMode(true);

        vm.expectCall(
            address(hubPeripheryDeployment.hubPeripheryFactory),
            abi.encodeWithSelector(IHubPeripheryFactory.createSecurityModule.selector),
            0
        );
        deploySecurityModule.run();

        assertEq(deploySecurityModule.deployedInstance(), address(0));
    }

    function testScript_DeployDirectDepositor() public {
        _forkHubChain();

        HubPeriphery memory hubPeripheryDeployment = _deployAndSetupHubPeriphery();

        // Depositor deployment
        deployDirectDepositor = new DeployDirectDepositor();
        deployDirectDepositor.setParams(
            address(hubPeripheryDeployment.hubPeripheryFactory), _hubTestFilename(), _hubTestFilename()
        );
        deployDirectDepositor.setImplemId(_implemId(".directDepositorImplemId"));
        deployDirectDepositor.run();

        DirectDepositor directDepositor = DirectDepositor(deployDirectDepositor.deployedInstance());
        assertTrue(hubPeripheryDeployment.hubPeripheryFactory.isDepositor(address(directDepositor)));
        assertEq(
            directDepositor.isWhitelistEnabled(),
            vm.parseJsonBool(deployDirectDepositor.inputJson(), ".whitelistStatus")
        );

        // Check that the output file is written
        assertEq(
            vm.parseJsonAddress(vm.readFile(deployDirectDepositor.outputPath()), ".DirectDepositor"),
            address(directDepositor)
        );
    }

    function testScript_DeployAsyncRedeemer() public {
        _forkHubChain();

        HubPeriphery memory hubPeripheryDeployment = _deployAndSetupHubPeriphery();

        // Redeemer deployment
        deployAsyncRedeemer = new DeployAsyncRedeemer();
        deployAsyncRedeemer.setParams(
            address(hubPeripheryDeployment.hubPeripheryFactory), _hubTestFilename(), _hubTestFilename()
        );
        deployAsyncRedeemer.setImplemId(_implemId(".asyncRedeemerImplemId"));
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

        // Check that the output file is written
        assertEq(
            vm.parseJsonAddress(vm.readFile(deployAsyncRedeemer.outputPath()), ".AsyncRedeemer"), address(asyncRedeemer)
        );
    }

    function testScript_DeployAsyncRedeemerFee() public {
        _forkHubChain();

        HubPeriphery memory hubPeripheryDeployment = _deployAndSetupHubPeriphery();

        // Redeemer deployment
        deployAsyncRedeemerFee = new DeployAsyncRedeemerFee();
        deployAsyncRedeemerFee.setParams(
            address(hubPeripheryDeployment.hubPeripheryFactory), _hubTestFilename(), _hubTestFilename()
        );
        deployAsyncRedeemerFee.setImplemId(_implemId(".asyncRedeemerFeeImplemId"));
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

        // Check that the output file is written
        assertEq(
            vm.parseJsonAddress(vm.readFile(deployAsyncRedeemerFee.outputPath()), ".AsyncRedeemerFee"),
            address(asyncRedeemerFee)
        );
    }

    function testScript_DeployWatermarkFeeManager() public {
        _forkHubChain();

        HubPeriphery memory hubPeripheryDeployment = _deployAndSetupHubPeriphery();

        // FeeManager deployment
        deployWatermarkFeeManager = new DeployWatermarkFeeManager();
        deployWatermarkFeeManager.setParams(
            address(hubPeripheryDeployment.hubPeripheryFactory), _hubTestFilename(), _hubTestFilename()
        );
        deployWatermarkFeeManager.setImplemId(_implemId(".watermarkFeeManagerImplemId"));
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

        // Check that the output file is written
        assertEq(
            vm.parseJsonAddress(vm.readFile(deployWatermarkFeeManager.outputPath()), ".WatermarkFeeManager"),
            address(watermarkFeeManager)
        );
    }

    /// @dev Forks the hub chain and grants ADMIN_ROLE on the live AccessManager, which the test hub periphery is bound
    ///      to, to the address the scripts broadcast from. The setup and instance scripts call restricted functions,
    ///      all defaulting to ADMIN_ROLE until `SetupHubPeripheryAM` has run.
    function _forkHubChain() internal {
        vm.createSelectFork({urlOrAlias: getChain(ETHEREUM_CHAIN_ID).chainAlias});

        string memory inputJson = vm.readFile(
            string.concat(vm.projectRoot(), "/script/deployments/inputs/hub-peripheries/", _hubTestFilename())
        );
        AccessManagerUpgradeable accessManager =
            AccessManagerUpgradeable(vm.parseJsonAddress(inputJson, ".accessManager"));
        uint64 adminRole = accessManager.ADMIN_ROLE();

        (,, address broadcaster) = vm.readCallers();

        vm.prank(LIVE_AM_ADMIN);
        accessManager.grantRole(adminRole, broadcaster, 0);
    }

    function _hubTestFilename() internal returns (string memory) {
        return string.concat(getChain(ETHEREUM_CHAIN_ID).name, "-Test.json");
    }

    function _spokeTestFilename() internal returns (string memory) {
        return string.concat(getChain(BASE_CHAIN_ID).name, "-Test.json");
    }

    /// @dev An implementation id of the hub test implementation ids file.
    function _implemId(string memory key) internal returns (uint16) {
        string memory implemIdsJson =
            vm.readFile(string.concat(vm.projectRoot(), "/script/deployments/inputs/implem-ids/", _hubTestFilename()));
        return uint16(vm.parseJsonUint(implemIdsJson, key));
    }

    /// @dev Deploys the hub periphery, writing the output file the setup and instance scripts read from.
    function _deployHubPeriphery() internal returns (HubPeriphery memory) {
        deployHubPeriphery = new DeployHubPeriphery();
        deployHubPeriphery.setFilenames(_hubTestFilename(), _hubTestFilename());
        deployHubPeriphery.run();

        return deployHubPeriphery.deployment();
    }

    function _setupHubPeripheryRegistry() internal {
        setupHubPeripheryRegistry = new SetupHubPeripheryRegistry();
        setupHubPeripheryRegistry.setFilenames(_hubTestFilename(), _hubTestFilename());
        setupHubPeripheryRegistry.setImplemIdsFilename(_hubTestFilename());
        setupHubPeripheryRegistry.run();
    }

    /// @dev The instance scripts need the component beacons registered.
    function _deployAndSetupHubPeriphery() internal returns (HubPeriphery memory hubPeripheryDeployment) {
        hubPeripheryDeployment = _deployHubPeriphery();
        _setupHubPeripheryRegistry();
    }
}
