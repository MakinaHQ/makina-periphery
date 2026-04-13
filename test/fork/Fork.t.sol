// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";

import {
    AccessManagerUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/manager/AccessManagerUpgradeable.sol";

import "@makina-core-test/base/Base.sol" as Core_Base;
import {ChainsInfo} from "@makina-core-test/utils/ChainsInfo.sol";
import {ChainRegistry} from "@makina-core/registries/ChainRegistry.sol";
import {HubCoreRegistry} from "@makina-core/registries/HubCoreRegistry.sol";
import {HubCoreFactory} from "@makina-core/factories/HubCoreFactory.sol";
import {OracleRegistry} from "@makina-core/registries/OracleRegistry.sol";
import {SwapModule} from "@makina-core/swap/SwapModule.sol";
import {TokenRegistry} from "@makina-core/registries/TokenRegistry.sol";

import {FlashloanAggregator} from "../../src/flashloans/FlashloanAggregator.sol";
import {HubPeripheryRegistry} from "../../src/registries/HubPeripheryRegistry.sol";
import {HubPeripheryFactory} from "../../src/factories/HubPeripheryFactory.sol";

import {Base} from "../base/Base.sol";

abstract contract Fork_Test is Base, Test, Core_Base.Base {
    address internal deployer;

    uint256 internal chainId;

    address internal usdc;
    address internal weth;

    address internal dao;
    address internal mechanic;
    address internal securityCouncil;

    FlashloanProviders internal flashloanProviders;

    // Hub Core
    AccessManagerUpgradeable internal accessManager;
    OracleRegistry internal oracleRegistry;
    TokenRegistry internal tokenRegistry;
    SwapModule internal swapModule;
    HubCoreRegistry internal hubCoreRegistry;
    ChainRegistry internal chainRegistry;
    HubCoreFactory internal hubCoreFactory;

    // Hub Periphery
    FlashloanAggregator internal flashloanAggregator;
    HubPeripheryRegistry internal hubPeripheryRegistry;
    HubPeripheryFactory internal hubPeripheryFactory;

    function setUp() public virtual {
        chainId = ChainsInfo.CHAIN_ID_ETHEREUM;
        ChainsInfo.ChainInfo memory chainInfo = ChainsInfo.getChainInfo(chainId);

        vm.createSelectFork({urlOrAlias: chainInfo.foundryAlias});

        string memory coreInputPath = string.concat(vm.projectRoot(), "/lib/makina-core/test/fork/constants/");
        string memory coreInputJson = vm.readFile(string.concat(coreInputPath, chainInfo.constantsFilename));

        string memory peripheryInputPath = string.concat(vm.projectRoot(), "/test/fork/constants/");
        string memory peripheryInputJson = vm.readFile(string.concat(peripheryInputPath, chainInfo.constantsFilename));

        deployer = address(this);
        usdc = vm.parseJsonAddress(coreInputJson, ".usdc");
        weth = vm.parseJsonAddress(coreInputJson, ".weth");
        dao = vm.parseJsonAddress(coreInputJson, ".dao");
        mechanic = vm.parseJsonAddress(coreInputJson, ".mechanic");
        securityCouncil = vm.parseJsonAddress(coreInputJson, ".securityCouncil");

        // read misc addresses from json
        flashloanProviders = FlashloanProviders({
            balancerV2Pool: vm.parseJsonAddress(peripheryInputJson, ".flashloanProviders.balancerV2Pool"),
            balancerV3Pool: vm.parseJsonAddress(peripheryInputJson, ".flashloanProviders.balancerV3Pool"),
            morphoPool: vm.parseJsonAddress(peripheryInputJson, ".flashloanProviders.morphoPool"),
            dssFlash: vm.parseJsonAddress(peripheryInputJson, ".flashloanProviders.dssFlash"),
            aaveV3AddressProvider: vm.parseJsonAddress(peripheryInputJson, ".flashloanProviders.aaveV3AddressProvider"),
            dai: vm.parseJsonAddress(peripheryInputJson, ".flashloanProviders.dai")
        });

        // hub Core
        Core_Base.Base.HubCore memory coreDeployment = deployHubCore(deployer, address(0));
        accessManager = coreDeployment.accessManager;
        hubCoreRegistry = coreDeployment.hubCoreRegistry;
        hubCoreFactory = coreDeployment.hubCoreFactory;
        setupHubCoreRegistry(coreDeployment);

        // Hub Periphery
        HubPeriphery memory peripheryDeployment =
            deployHubPeriphery(address(accessManager), address(hubCoreRegistry), flashloanProviders);
        flashloanAggregator = peripheryDeployment.flashloanAggregator;
        hubPeripheryRegistry = peripheryDeployment.hubPeripheryRegistry;
        hubPeripheryFactory = peripheryDeployment.hubPeripheryFactory;
    }

    function _deployWeirollVM() internal pure override returns (address) {
        return address(0);
    }
}
