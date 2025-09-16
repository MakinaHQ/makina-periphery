// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";

import "@makina-core-test/base/Base.sol" as Core_base;

import {AccessManagerUpgradeable} from "@openzeppelin/contracts-upgradeable/access/manager/AccessManagerUpgradeable.sol";
import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";

import {ICaliber} from "@makina-core/interfaces/ICaliber.sol";
import {IMachine} from "@makina-core/interfaces/IMachine.sol";
import {IMakinaGovernable} from "@makina-core/interfaces/IMakinaGovernable.sol";
import {MockWormhole} from "@makina-core-test/mocks/MockWormhole.sol";
import {Caliber} from "@makina-core/caliber/Caliber.sol";
import {ChainRegistry} from "@makina-core/registries/ChainRegistry.sol";
import {HubCoreRegistry} from "@makina-core/registries/HubCoreRegistry.sol";
import {HubCoreFactory} from "@makina-core/factories/HubCoreFactory.sol";
import {Machine} from "@makina-core/machine/Machine.sol";
import {OracleRegistry} from "@makina-core/registries/OracleRegistry.sol";
import {SwapModule} from "@makina-core/swap/SwapModule.sol";
import {TokenRegistry} from "@makina-core/registries/TokenRegistry.sol";

import {Constants} from "../utils/Constants.sol";
import {CoreHelpers} from "../utils/CoreHelpers.sol";
import {FlashloanAggregator} from "../../src/flashloans/FlashloanAggregator.sol";
import {HubPeripheryRegistry} from "../../src/registries/HubPeripheryRegistry.sol";
import {HubPeripheryFactory} from "../../src/factories/HubPeripheryFactory.sol";
import {MetaMorphoOracleFactory} from "../../src/factories/MetaMorphoOracleFactory.sol";

import {Base} from "./Base.sol";

abstract contract Base_Test is Base, Test, Constants, CoreHelpers {
    address public deployer;

    uint256 public hubChainId;

    address public dao;
    address public mechanic;
    address public securityCouncil;
    address public riskManager;
    address public riskManagerTimelock;

    // Flashloan Aggregator
    FlashloanAggregator public flashloanAggregator;

    // Registry and Factory
    HubPeripheryRegistry public hubPeripheryRegistry;
    HubPeripheryFactory public hubPeripheryFactory;

    // Machine Depositors
    UpgradeableBeacon public directDepositorBeacon;

    // Machine Redeemers
    UpgradeableBeacon public asyncRedeemerBeacon;

    // Machine Fee Managers
    UpgradeableBeacon public watermarkFeeManagerBeacon;

    // Security Module
    UpgradeableBeacon public securityModuleBeacon;

    // MetaMorpho Oracle Factory
    MetaMorphoOracleFactory public metaMorphoOracleFactory;

    function setUp() public virtual {
        deployer = address(this);
        dao = makeAddr("MakinaDAO");
        mechanic = makeAddr("Mechanic");
        securityCouncil = makeAddr("SecurityCouncil");
        riskManager = makeAddr("RiskManager");
        riskManagerTimelock = makeAddr("RiskManagerTimelock");
    }
}

abstract contract Base_Hub_Test is Base_Test {
    MockWormhole public wormhole;

    address public balancerV2Pool;
    address public balancerV3Pool;
    address public morphoPool;
    address public dssFlash;
    address public aaveV3AddressProvider;
    address public dai;

    // Hub Core
    AccessManagerUpgradeable public accessManager;
    OracleRegistry public oracleRegistry;
    TokenRegistry public tokenRegistry;
    SwapModule public swapModule;
    HubCoreRegistry public hubCoreRegistry;
    ChainRegistry public chainRegistry;
    HubCoreFactory public hubCoreFactory;

    function setUp() public virtual override {
        Base_Test.setUp();
        hubChainId = block.chainid;

        wormhole = _deployWormhole(WORMHOLE_HUB_CHAIN_ID, hubChainId);

        balancerV2Pool = makeAddr("BalancerV2Pool");
        balancerV3Pool = makeAddr("BalancerV3Pool");
        morphoPool = makeAddr("MorphoPool");
        dssFlash = makeAddr("DssFlash");
        aaveV3AddressProvider = makeAddr("AaveV3AddressProvider");
        dai = makeAddr("DAI");

        // Hub Core
        Core_base.Base.HubCore memory hubCore = _deployHubCore(deployer, dao, address(wormhole));
        accessManager = hubCore.accessManager;
        oracleRegistry = hubCore.oracleRegistry;
        swapModule = hubCore.swapModule;
        hubCoreRegistry = hubCore.hubCoreRegistry;
        tokenRegistry = hubCore.tokenRegistry;
        chainRegistry = hubCore.chainRegistry;
        hubCoreFactory = hubCore.hubCoreFactory;

        // Hub Periphery
        HubPeriphery memory hubPeriphery = deployHubPeriphery(
            address(accessManager),
            address(hubCore.hubCoreFactory),
            FlashloanProviders({
                balancerV2Pool: balancerV2Pool,
                balancerV3Pool: balancerV3Pool,
                morphoPool: morphoPool,
                dssFlash: dssFlash,
                aaveV3AddressProvider: aaveV3AddressProvider,
                dai: dai
            }),
            dao
        );
        flashloanAggregator = hubPeriphery.flashloanAggregator;
        hubPeripheryRegistry = hubPeriphery.hubPeripheryRegistry;
        hubPeripheryFactory = hubPeriphery.hubPeripheryFactory;
        directDepositorBeacon = hubPeriphery.directDepositorBeacon;
        asyncRedeemerBeacon = hubPeriphery.asyncRedeemerBeacon;
        watermarkFeeManagerBeacon = hubPeriphery.watermarkFeeManagerBeacon;
        securityModuleBeacon = hubPeriphery.securityModuleBeacon;
        metaMorphoOracleFactory = hubPeriphery.metaMorphoOracleFactory;

        registerFlashloanAggregator(address(hubCore.hubCoreRegistry), address(flashloanAggregator));
        registerHubPeripheryFactory(address(hubPeripheryRegistry), address(hubPeripheryFactory));
        registerSecurityModuleBeacon(address(hubPeripheryRegistry), address(securityModuleBeacon));

        uint16[] memory mdImplemIds = new uint16[](1);
        mdImplemIds[0] = DIRECT_DEPOSITOR_IMPLEM_ID;
        address[] memory mdBeacons = new address[](1);
        mdBeacons[0] = address(hubPeriphery.directDepositorBeacon);
        registerDepositorBeacons(address(hubPeripheryRegistry), mdImplemIds, mdBeacons);

        uint16[] memory mrImplemIds = new uint16[](1);
        mrImplemIds[0] = ASYNC_REDEEMER_IMPLEM_ID;
        address[] memory mrBeacons = new address[](1);
        mrBeacons[0] = address(hubPeriphery.asyncRedeemerBeacon);
        registerRedeemerBeacons(address(hubPeripheryRegistry), mrImplemIds, mrBeacons);

        uint16[] memory fmImplemIds = new uint16[](1);
        fmImplemIds[0] = WATERMARK_FEE_MANAGER_IMPLEM_ID;
        address[] memory fmBeacons = new address[](1);
        fmBeacons[0] = address(hubPeriphery.watermarkFeeManagerBeacon);
        registerFeeManagerBeacons(address(hubPeripheryRegistry), fmImplemIds, fmBeacons);

        _setupAccessManager(accessManager, dao);
    }

    function _deployMachine(address _accountingToken, address _depositor, address _redeemer, address _machineFeeManager)
        public
        returns (Machine, Caliber)
    {
        vm.prank(dao);
        Machine _machine = Machine(
            hubCoreFactory.createMachine(
                IMachine.MachineInitParams({
                    initialDepositor: _depositor,
                    initialRedeemer: _redeemer,
                    initialFeeManager: _machineFeeManager,
                    initialCaliberStaleThreshold: DEFAULT_MACHINE_CALIBER_STALE_THRESHOLD,
                    initialMaxFixedFeeAccrualRate: DEFAULT_MACHINE_MAX_FIXED_FEE_ACCRUAL_RATE,
                    initialMaxPerfFeeAccrualRate: DEFAULT_MACHINE_MAX_PERF_FEE_ACCRUAL_RATE,
                    initialFeeMintCooldown: DEFAULT_MACHINE_FEE_MINT_COOLDOWN,
                    initialShareLimit: DEFAULT_MACHINE_SHARE_LIMIT
                }),
                ICaliber.CaliberInitParams({
                    initialPositionStaleThreshold: DEFAULT_CALIBER_POS_STALE_THRESHOLD,
                    initialAllowedInstrRoot: bytes32(0),
                    initialTimelockDuration: DEFAULT_CALIBER_ROOT_UPDATE_TIMELOCK,
                    initialMaxPositionIncreaseLossBps: DEFAULT_CALIBER_MAX_POS_INCREASE_LOSS_BPS,
                    initialMaxPositionDecreaseLossBps: DEFAULT_CALIBER_MAX_POS_DECREASE_LOSS_BPS,
                    initialMaxSwapLossBps: DEFAULT_CALIBER_MAX_SWAP_LOSS_BPS,
                    initialCooldownDuration: DEFAULT_CALIBER_COOLDOWN_DURATION
                }),
                IMakinaGovernable.MakinaGovernableInitParams({
                    initialMechanic: mechanic,
                    initialSecurityCouncil: securityCouncil,
                    initialRiskManager: riskManager,
                    initialRiskManagerTimelock: riskManagerTimelock,
                    initialAuthority: address(accessManager)
                }),
                _accountingToken,
                DEFAULT_MACHINE_SHARE_TOKEN_NAME,
                DEFAULT_MACHINE_SHARE_TOKEN_SYMBOL,
                TEST_DEPLOYMENT_SALT
            )
        );
        Caliber _caliber = Caliber(_machine.hubCaliber());
        return (_machine, _caliber);
    }
}
