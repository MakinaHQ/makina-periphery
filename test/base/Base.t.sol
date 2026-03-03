// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";

import "@makina-core-test/base/Base.sol" as Core_Base;
import "@makina-core-test/utils/Constants.sol" as Core_Constants;

import {AccessManagerUpgradeable} from "@openzeppelin/contracts-upgradeable/access/manager/AccessManagerUpgradeable.sol";
import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";

import {IBridgeAdapterFactory} from "@makina-core/interfaces/IBridgeAdapterFactory.sol";
import {ICaliber} from "@makina-core/interfaces/ICaliber.sol";
import {IMachine} from "@makina-core/interfaces/IMachine.sol";
import {IMakinaGovernable} from "@makina-core/interfaces/IMakinaGovernable.sol";
import {IPreDepositVault} from "@makina-core/interfaces/IPreDepositVault.sol";
import {Caliber} from "@makina-core/caliber/Caliber.sol";
import {ChainRegistry} from "@makina-core/registries/ChainRegistry.sol";
import {HubCoreRegistry} from "@makina-core/registries/HubCoreRegistry.sol";
import {HubCoreFactory} from "@makina-core/factories/HubCoreFactory.sol";
import {Machine} from "@makina-core/machine/Machine.sol";
import {OracleRegistry} from "@makina-core/registries/OracleRegistry.sol";
import {PreDepositVault} from "@makina-core/pre-deposit/PreDepositVault.sol";
import {Roles} from "@makina-core/libraries/Roles.sol";
import {SwapModule} from "@makina-core/swap/SwapModule.sol";
import {TokenRegistry} from "@makina-core/registries/TokenRegistry.sol";

import {Constants} from "../utils/Constants.sol";
import {FlashloanAggregator} from "../../src/flashloans/FlashloanAggregator.sol";
import {HubPeripheryRegistry} from "../../src/registries/HubPeripheryRegistry.sol";
import {HubPeripheryFactory} from "../../src/factories/HubPeripheryFactory.sol";
import {MachineShareOracleFactory} from "../../src/factories/MachineShareOracleFactory.sol";
import {MetaMorphoOracleFactory} from "../../src/factories/MetaMorphoOracleFactory.sol";

import {Base} from "./Base.sol";

abstract contract Base_Test is Base, Test, Constants, Core_Base.Base, Core_Constants.Constants {
    address internal deployer;

    uint256 internal hubChainId;

    address internal dao;
    address internal mechanic;
    address internal securityCouncil;
    address internal riskManager;
    address internal riskManagerTimelock;

    // Core contracts
    AccessManagerUpgradeable internal accessManager;
    OracleRegistry internal oracleRegistry;
    TokenRegistry internal tokenRegistry;
    SwapModule internal swapModule;

    address internal coreFactory;

    // Flashloan Aggregator
    FlashloanAggregator internal flashloanAggregator;

    // Registry and Factory
    HubPeripheryRegistry internal hubPeripheryRegistry;
    HubPeripheryFactory internal hubPeripheryFactory;

    // Machine Depositors
    UpgradeableBeacon internal directDepositorBeacon;

    // Machine Redeemers
    UpgradeableBeacon internal asyncRedeemerBeacon;
    UpgradeableBeacon internal asyncRedeemerFeeBeacon;

    // Machine Fee Managers
    UpgradeableBeacon internal watermarkFeeManagerBeacon;

    // Security Module
    UpgradeableBeacon internal securityModuleBeacon;

    // MetaMorpho Oracle Factory
    MetaMorphoOracleFactory internal metaMorphoOracleFactory;

    // Machine Share Oracle Beacon and Factory
    UpgradeableBeacon internal machineShareOracleBeacon;
    MachineShareOracleFactory internal machineShareOracleFactory;

    function setUp() public virtual {
        deployer = address(this);
        dao = makeAddr("MakinaDAO");
        mechanic = makeAddr("Mechanic");
        securityCouncil = makeAddr("SecurityCouncil");
        riskManager = makeAddr("RiskManager");
        riskManagerTimelock = makeAddr("RiskManagerTimelock");
    }

    function setupAccessManagerRoles() internal {
        // Grant roles to the relevant accounts
        accessManager.grantRole(accessManager.ADMIN_ROLE(), dao, 0);
        accessManager.grantRole(accessManager.ADMIN_ROLE(), coreFactory, 0);
        accessManager.grantRole(Roles.INFRA_CONFIG_ROLE, dao, 0);
        accessManager.grantRole(Roles.STRATEGY_DEPLOYMENT_ROLE, dao, 0);
        accessManager.grantRole(Roles.STRATEGY_COMPONENTS_SETUP_ROLE, dao, 0);
        accessManager.grantRole(Roles.STRATEGY_MANAGEMENT_CONFIG_ROLE, dao, 0);
        accessManager.grantRole(Roles.INFRA_UPGRADE_ROLE, dao, 0);
        accessManager.grantRole(Roles.GUARDIAN_ROLE, securityCouncil, 0);

        // Revoke roles from the deployer
        accessManager.revokeRole(accessManager.ADMIN_ROLE(), address(deployer));
    }

    function setupAccessManagerRolesAndOwnership() internal {
        setupAccessManagerRoles();
        transferAccessManagerOwnership(accessManager);
    }

    function _deployWeirollVM() internal pure override returns (address) {
        return address(0);
    }
}

abstract contract Base_Hub_Test is Base_Test {
    address internal balancerV2Pool;
    address internal balancerV3Pool;
    address internal morphoPool;
    address internal dssFlash;
    address internal aaveV3AddressProvider;
    address internal dai;

    // Hub Core
    HubCoreRegistry internal hubCoreRegistry;
    ChainRegistry internal chainRegistry;
    HubCoreFactory internal hubCoreFactory;

    function setUp() public virtual override {
        Base_Test.setUp();
        hubChainId = block.chainid;

        balancerV2Pool = makeAddr("BalancerV2Pool");
        balancerV3Pool = makeAddr("BalancerV3Pool");
        morphoPool = makeAddr("MorphoPool");
        dssFlash = makeAddr("DssFlash");
        aaveV3AddressProvider = makeAddr("AaveV3AddressProvider");
        dai = makeAddr("DAI");

        // Hub Core
        Core_Base.Base.HubCore memory coreDeployment = deployHubCore(deployer, address(0));
        accessManager = coreDeployment.accessManager;
        oracleRegistry = coreDeployment.oracleRegistry;
        swapModule = coreDeployment.swapModule;
        hubCoreRegistry = coreDeployment.hubCoreRegistry;
        tokenRegistry = coreDeployment.tokenRegistry;
        chainRegistry = coreDeployment.chainRegistry;
        hubCoreFactory = coreDeployment.hubCoreFactory;

        setupHubCoreRegistry(coreDeployment);

        // Hub Periphery
        HubPeriphery memory peripheryDeployment = deployHubPeriphery(
            address(accessManager),
            address(hubCoreRegistry),
            FlashloanProviders({
                balancerV2Pool: balancerV2Pool,
                balancerV3Pool: balancerV3Pool,
                morphoPool: morphoPool,
                dssFlash: dssFlash,
                aaveV3AddressProvider: aaveV3AddressProvider,
                dai: dai
            })
        );
        flashloanAggregator = peripheryDeployment.flashloanAggregator;
        hubPeripheryRegistry = peripheryDeployment.hubPeripheryRegistry;
        hubPeripheryFactory = peripheryDeployment.hubPeripheryFactory;
        directDepositorBeacon = peripheryDeployment.directDepositorBeacon;
        asyncRedeemerBeacon = peripheryDeployment.asyncRedeemerBeacon;
        asyncRedeemerFeeBeacon = peripheryDeployment.asyncRedeemerFeeBeacon;
        watermarkFeeManagerBeacon = peripheryDeployment.watermarkFeeManagerBeacon;
        securityModuleBeacon = peripheryDeployment.securityModuleBeacon;
        metaMorphoOracleFactory = peripheryDeployment.metaMorphoOracleFactory;
        machineShareOracleBeacon = peripheryDeployment.machineShareOracleBeacon;
        machineShareOracleFactory = peripheryDeployment.machineShareOracleFactory;

        registerFlashloanAggregator(address(coreDeployment.hubCoreRegistry), address(flashloanAggregator));
        registerHubPeripheryFactory(address(hubPeripheryRegistry), address(hubPeripheryFactory));
        registerSecurityModuleBeacon(address(hubPeripheryRegistry), address(securityModuleBeacon));

        uint16[] memory mdImplemIds = new uint16[](1);
        mdImplemIds[0] = DIRECT_DEPOSITOR_IMPLEM_ID;
        address[] memory mdBeacons = new address[](1);
        mdBeacons[0] = address(peripheryDeployment.directDepositorBeacon);
        registerDepositorBeacons(address(hubPeripheryRegistry), mdImplemIds, mdBeacons);

        uint16[] memory mrImplemIds = new uint16[](2);
        mrImplemIds[0] = ASYNC_REDEEMER_IMPLEM_ID;
        mrImplemIds[1] = ASYNC_REDEEMER_FEE_IMPLEM_ID;
        address[] memory mrBeacons = new address[](2);
        mrBeacons[0] = address(peripheryDeployment.asyncRedeemerBeacon);
        mrBeacons[1] = address(peripheryDeployment.asyncRedeemerFeeBeacon);
        registerRedeemerBeacons(address(hubPeripheryRegistry), mrImplemIds, mrBeacons);

        uint16[] memory fmImplemIds = new uint16[](1);
        fmImplemIds[0] = WATERMARK_FEE_MANAGER_IMPLEM_ID;
        address[] memory fmBeacons = new address[](1);
        fmBeacons[0] = address(peripheryDeployment.watermarkFeeManagerBeacon);
        registerFeeManagerBeacons(address(hubPeripheryRegistry), fmImplemIds, fmBeacons);

        setupHubCoreAMFunctionRoles(coreDeployment);
        setupHubPeripheryAMFunctionRoles(address(accessManager), peripheryDeployment);

        coreFactory = address(hubCoreFactory);
        setupAccessManagerRolesAndOwnership();
    }

    function _deployPreDepositVault(address _depositToken, address _accountingToken)
        internal
        returns (PreDepositVault)
    {
        vm.prank(dao);
        PreDepositVault _preDepositVault = PreDepositVault(
            hubCoreFactory.createPreDepositVault(
                IPreDepositVault.PreDepositVaultInitParams({
                    initialShareLimit: DEFAULT_MACHINE_SHARE_LIMIT,
                    initialWhitelistMode: false,
                    initialRiskManager: address(0),
                    initialAuthority: address(accessManager)
                }),
                _depositToken,
                _accountingToken,
                DEFAULT_MACHINE_SHARE_TOKEN_NAME,
                DEFAULT_MACHINE_SHARE_TOKEN_SYMBOL,
                true
            )
        );
        return _preDepositVault;
    }

    function _deployMachineFromPreDeposit(
        address _preDepositVault,
        address _depositor,
        address _redeemer,
        address _feeManager
    ) internal returns (Machine, Caliber) {
        vm.prank(dao);
        Machine _machine = Machine(
            hubCoreFactory.createMachineFromPreDeposit(
                IMachine.MachineInitParams({
                    initialDepositor: _depositor,
                    initialRedeemer: _redeemer,
                    initialFeeManager: _feeManager,
                    initialCaliberStaleThreshold: DEFAULT_MACHINE_CALIBER_STALE_THRESHOLD,
                    initialMaxFixedFeeAccrualRate: DEFAULT_MACHINE_MAX_FIXED_FEE_ACCRUAL_RATE,
                    initialMaxPerfFeeAccrualRate: DEFAULT_MACHINE_MAX_PERF_FEE_ACCRUAL_RATE,
                    initialFeeMintCooldown: DEFAULT_MACHINE_FEE_MINT_COOLDOWN,
                    initialShareLimit: DEFAULT_MACHINE_SHARE_LIMIT,
                    initialMaxSharePriceChangeRate: DEFAULT_MACHINE_MAX_SHARE_PRICE_CHANGE_RATE
                }),
                ICaliber.CaliberInitParams({
                    initialPositionStaleThreshold: DEFAULT_CALIBER_POS_STALE_THRESHOLD,
                    initialAllowedInstrRoot: bytes32(0),
                    initialTimelockDuration: DEFAULT_CALIBER_ROOT_UPDATE_TIMELOCK,
                    initialMaxPositionIncreaseLossBps: DEFAULT_CALIBER_MAX_POS_INCREASE_LOSS_BPS,
                    initialMaxPositionDecreaseLossBps: DEFAULT_CALIBER_MAX_POS_DECREASE_LOSS_BPS,
                    initialMaxSwapLossBps: DEFAULT_CALIBER_MAX_SWAP_LOSS_BPS,
                    initialCooldownDuration: DEFAULT_CALIBER_COOLDOWN_DURATION,
                    initialBaseTokens: new address[](0)
                }),
                IMakinaGovernable.MakinaGovernableInitParams({
                    initialMechanic: mechanic,
                    initialSecurityCouncil: securityCouncil,
                    initialRiskManager: riskManager,
                    initialRiskManagerTimelock: riskManagerTimelock,
                    initialAuthority: address(accessManager),
                    initialRestrictedAccountingMode: false,
                    initialAccountingAgents: new address[](0)
                }),
                new IBridgeAdapterFactory.BridgeAdapterInitParams[](0),
                _preDepositVault,
                TEST_DEPLOYMENT_SALT,
                true
            )
        );
        Caliber _caliber = Caliber(_machine.hubCaliber());
        return (_machine, _caliber);
    }

    function _deployMachine(address _accountingToken, address _depositor, address _redeemer, address _feeManager)
        internal
        returns (Machine, Caliber)
    {
        vm.prank(dao);
        Machine _machine = Machine(
            hubCoreFactory.createMachine(
                IMachine.MachineInitParams({
                    initialDepositor: _depositor,
                    initialRedeemer: _redeemer,
                    initialFeeManager: _feeManager,
                    initialCaliberStaleThreshold: DEFAULT_MACHINE_CALIBER_STALE_THRESHOLD,
                    initialMaxFixedFeeAccrualRate: DEFAULT_MACHINE_MAX_FIXED_FEE_ACCRUAL_RATE,
                    initialMaxPerfFeeAccrualRate: DEFAULT_MACHINE_MAX_PERF_FEE_ACCRUAL_RATE,
                    initialFeeMintCooldown: DEFAULT_MACHINE_FEE_MINT_COOLDOWN,
                    initialShareLimit: DEFAULT_MACHINE_SHARE_LIMIT,
                    initialMaxSharePriceChangeRate: DEFAULT_MACHINE_MAX_SHARE_PRICE_CHANGE_RATE
                }),
                ICaliber.CaliberInitParams({
                    initialPositionStaleThreshold: DEFAULT_CALIBER_POS_STALE_THRESHOLD,
                    initialAllowedInstrRoot: bytes32(0),
                    initialTimelockDuration: DEFAULT_CALIBER_ROOT_UPDATE_TIMELOCK,
                    initialMaxPositionIncreaseLossBps: DEFAULT_CALIBER_MAX_POS_INCREASE_LOSS_BPS,
                    initialMaxPositionDecreaseLossBps: DEFAULT_CALIBER_MAX_POS_DECREASE_LOSS_BPS,
                    initialMaxSwapLossBps: DEFAULT_CALIBER_MAX_SWAP_LOSS_BPS,
                    initialCooldownDuration: DEFAULT_CALIBER_COOLDOWN_DURATION,
                    initialBaseTokens: new address[](0)
                }),
                IMakinaGovernable.MakinaGovernableInitParams({
                    initialMechanic: mechanic,
                    initialSecurityCouncil: securityCouncil,
                    initialRiskManager: riskManager,
                    initialRiskManagerTimelock: riskManagerTimelock,
                    initialAuthority: address(accessManager),
                    initialRestrictedAccountingMode: false,
                    initialAccountingAgents: new address[](0)
                }),
                new IBridgeAdapterFactory.BridgeAdapterInitParams[](0),
                _accountingToken,
                DEFAULT_MACHINE_SHARE_TOKEN_NAME,
                DEFAULT_MACHINE_SHARE_TOKEN_SYMBOL,
                TEST_DEPLOYMENT_SALT,
                true
            )
        );
        Caliber _caliber = Caliber(_machine.hubCaliber());
        return (_machine, _caliber);
    }
}
