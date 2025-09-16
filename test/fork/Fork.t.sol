// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";

import {AccessManagerUpgradeable} from "@openzeppelin/contracts-upgradeable/access/manager/AccessManagerUpgradeable.sol";

import "@makina-core-test/base/Base.sol" as Core_base;
import {ChainsInfo} from "@makina-core-test/utils/ChainsInfo.sol";
import {ChainRegistry} from "@makina-core/registries/ChainRegistry.sol";
import {HubCoreRegistry} from "@makina-core/registries/HubCoreRegistry.sol";
import {HubCoreFactory} from "@makina-core/factories/HubCoreFactory.sol";
import {OracleRegistry} from "@makina-core/registries/OracleRegistry.sol";
import {SwapModule} from "@makina-core/swap/SwapModule.sol";
import {TokenRegistry} from "@makina-core/registries/TokenRegistry.sol";

import {CoreHelpers} from "../utils/CoreHelpers.sol";
import {FlashloanAggregator} from "../../src/flashloans/FlashloanAggregator.sol";
import {HubPeripheryRegistry} from "../../src/registries/HubPeripheryRegistry.sol";
import {HubPeripheryFactory} from "../../src/factories/HubPeripheryFactory.sol";

import {Base} from "../base/Base.sol";

abstract contract Fork_Test is Base, Test, CoreHelpers {
    address public deployer;

    uint256 public chainId;

    address public usdc;
    address public weth;

    address public dao;
    address public mechanic;
    address public securityCouncil;

    FlashloanProviders public flashloanProviders;

    // Hub Core
    AccessManagerUpgradeable public accessManager;
    OracleRegistry public oracleRegistry;
    TokenRegistry public tokenRegistry;
    SwapModule public swapModule;
    HubCoreRegistry public hubCoreRegistry;
    ChainRegistry public chainRegistry;
    HubCoreFactory public hubCoreFactory;

    // Hub Periphery
    FlashloanAggregator public flashloanAggregator;
    HubPeripheryRegistry public hubPeripheryRegistry;
    HubPeripheryFactory public hubPeripheryFactory;

    function setUp() public virtual {
        chainId = ChainsInfo.CHAIN_ID_ETHEREUM;
        ChainsInfo.ChainInfo memory chainInfo = ChainsInfo.getChainInfo(chainId);

        vm.createSelectFork({urlOrAlias: chainInfo.foundryAlias});

        string memory coreInputPath = string.concat(vm.projectRoot(), "/lib/makina-core/test/fork/constants/");
        string memory coreInputJson = vm.readFile(string.concat(coreInputPath, chainInfo.constantsFilename));

        string memory peripheryInputPath = string.concat(vm.projectRoot(), "/test/fork/constants/");
        string memory peripheryInputJson = vm.readFile(string.concat(peripheryInputPath, chainInfo.constantsFilename));

        deployer = address(this);
        usdc = abi.decode(vm.parseJson(coreInputJson, ".usdc"), (address));
        weth = abi.decode(vm.parseJson(coreInputJson, ".weth"), (address));
        dao = abi.decode(vm.parseJson(coreInputJson, ".dao"), (address));
        mechanic = abi.decode(vm.parseJson(coreInputJson, ".mechanic"), (address));
        securityCouncil = abi.decode(vm.parseJson(coreInputJson, ".securityCouncil"), (address));

        // read misc addresses from json
        flashloanProviders = FlashloanProviders({
            balancerV2Pool: abi.decode(vm.parseJson(peripheryInputJson, ".flashloanProviders.balancerV2Pool"), (address)),
            balancerV3Pool: abi.decode(vm.parseJson(peripheryInputJson, ".flashloanProviders.balancerV3Pool"), (address)),
            morphoPool: abi.decode(vm.parseJson(peripheryInputJson, ".flashloanProviders.morphoPool"), (address)),
            dssFlash: abi.decode(vm.parseJson(peripheryInputJson, ".flashloanProviders.dssFlash"), (address)),
            aaveV3AddressProvider: abi.decode(
                vm.parseJson(peripheryInputJson, ".flashloanProviders.aaveV3AddressProvider"), (address)
            ),
            dai: abi.decode(vm.parseJson(peripheryInputJson, ".flashloanProviders.dai"), (address))
        });

        // deploy core contracts
        address wormhole = abi.decode(vm.parseJson(coreInputJson, ".wormhole"), (address));
        Core_base.Base.HubCore memory hubCore = _deployHubCore(deployer, dao, wormhole);
        accessManager = hubCore.accessManager;
        oracleRegistry = hubCore.oracleRegistry;
        swapModule = hubCore.swapModule;
        hubCoreRegistry = hubCore.hubCoreRegistry;
        tokenRegistry = hubCore.tokenRegistry;
        chainRegistry = hubCore.chainRegistry;
        hubCoreFactory = hubCore.hubCoreFactory;

        // Hub Periphery
        HubPeriphery memory hubPeriphery =
            deployHubPeriphery(address(accessManager), address(hubCore.hubCoreFactory), flashloanProviders, dao);
        flashloanAggregator = hubPeriphery.flashloanAggregator;
        hubPeripheryRegistry = hubPeriphery.hubPeripheryRegistry;
        hubPeripheryFactory = hubPeriphery.hubPeripheryFactory;

        registerFlashloanAggregator(address(hubCore.hubCoreRegistry), address(flashloanAggregator));
        registerHubPeripheryFactory(address(hubPeripheryRegistry), address(hubPeripheryFactory));
        setupHubPeripheryAMFunctionRoles(address(accessManager), hubPeriphery);
        _setupAccessManager(accessManager, dao);
    }
}
