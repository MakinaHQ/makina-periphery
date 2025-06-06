// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";

import "@makina-core-test/base/Base.sol" as Core_base;

import {AccessManagerUpgradeable} from "@openzeppelin/contracts-upgradeable/access/manager/AccessManagerUpgradeable.sol";

import {MockWormhole} from "@makina-core-test/mocks/MockWormhole.sol";
import {ChainRegistry} from "@makina-core/registries/ChainRegistry.sol";
import {HubCoreRegistry} from "@makina-core/registries/HubCoreRegistry.sol";
import {HubCoreFactory} from "@makina-core/factories/HubCoreFactory.sol";
import {OracleRegistry} from "@makina-core/registries/OracleRegistry.sol";
import {SwapModule} from "@makina-core/swap/SwapModule.sol";
import {TokenRegistry} from "@makina-core/registries/TokenRegistry.sol";

import {Constants} from "../utils/Constants.sol";
import {CoreHelpers} from "../utils/CoreHelpers.sol";
import {FlashloanAggregator} from "../../src/flashloans/FlashloanAggregator.sol";
import {HubPeripheryRegistry} from "../../src/registries/HubPeripheryRegistry.sol";
import {HubPeripheryFactory} from "../../src/factories/HubPeripheryFactory.sol";

import {Base} from "./Base.sol";

abstract contract Base_Test is Base, Test, Constants, CoreHelpers {
    address public deployer;

    uint256 public hubChainId;

    address public dao;
    address public mechanic;
    address public securityCouncil;
    address public riskManager;
    address public riskManagerTimelock;

    FlashloanAggregator public flashloanAggregator;
    HubPeripheryRegistry public hubPeripheryRegistry;
    HubPeripheryFactory public hubPeripheryFactory;

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
        HubPeriphery memory hubPeriphery = deployPeriphery(
            address(accessManager),
            address(hubCore.hubCoreFactory),
            dao,
            FlashLoanAggregatorInitParams({
                balancerV2Pool: balancerV2Pool,
                balancerV3Pool: balancerV3Pool,
                morphoPool: morphoPool,
                dssFlash: dssFlash,
                aaveV3AddressProvider: aaveV3AddressProvider,
                dai: dai
            })
        );
        flashloanAggregator = hubPeriphery.flashloanAggregator;
        hubPeripheryRegistry = hubPeriphery.hubPeripheryRegistry;
        hubPeripheryFactory = hubPeriphery.hubPeripheryFactory;

        registerFlashloanAggregator(address(hubCore.hubCoreRegistry), address(flashloanAggregator));
        registerHubPeripheryFactory(address(hubPeripheryRegistry), address(hubPeripheryFactory));
        _setupAccessManager(accessManager, dao);
    }
}
