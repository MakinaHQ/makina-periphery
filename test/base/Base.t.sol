// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";

import "@makina-core-test/base/Base.sol" as Core_base;

import {AccessManagerUpgradeable} from "@openzeppelin/contracts-upgradeable/access/manager/AccessManagerUpgradeable.sol";
import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import {MockWormhole} from "@makina-core-test/mocks/MockWormhole.sol";
import {Caliber} from "@makina-core/caliber/Caliber.sol";
import {ChainRegistry} from "@makina-core/registries/ChainRegistry.sol";
import {HubCoreRegistry} from "@makina-core/registries/HubCoreRegistry.sol";
import {Machine} from "@makina-core/machine/Machine.sol";
import {HubCoreFactory} from "@makina-core/factories/HubCoreFactory.sol";
import {OracleRegistry} from "@makina-core/registries/OracleRegistry.sol";
import {PreDepositVault} from "@makina-core/pre-deposit/PreDepositVault.sol";
import {SwapModule} from "@makina-core/swap/SwapModule.sol";
import {TokenRegistry} from "@makina-core/registries/TokenRegistry.sol";

import {Constants} from "../utils/Constants.sol";
import {FlashloanAggregator} from "../../src/flashloans/FlashloanAggregator.sol";

import {Base} from "./Base.sol";

abstract contract Base_Test is Base, Test, Constants {
    address public deployer;

    uint256 public hubChainId;

    address public dao;
    address public mechanic;
    address public securityCouncil;
    address public riskManager;
    address public riskManagerTimelock;

    FlashloanAggregator public flashloanAggregator;

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

        wormhole = _deployWormhole();

        balancerV2Pool = makeAddr("BalancerV2Pool");
        balancerV3Pool = makeAddr("BalancerV3Pool");
        morphoPool = makeAddr("MorphoPool");
        dssFlash = makeAddr("DssFlash");
        aaveV3AddressProvider = makeAddr("AaveV3AddressProvider");
        dai = makeAddr("DAI");

        // Hub Core
        Core_base.Base.HubCore memory hubCore = _deployHubCore();
        accessManager = hubCore.accessManager;
        oracleRegistry = hubCore.oracleRegistry;
        swapModule = hubCore.swapModule;
        hubCoreRegistry = hubCore.hubCoreRegistry;
        tokenRegistry = hubCore.tokenRegistry;
        chainRegistry = hubCore.chainRegistry;
        hubCoreFactory = hubCore.hubCoreFactory;

        // Periphery
        Periphery memory periphery = deployPeriphery(
            address(hubCore.hubCoreFactory),
            FlashloanProviders({
                _balancerV2Pool: balancerV2Pool,
                _balancerV3Pool: balancerV3Pool,
                _morphoPool: morphoPool,
                _dssFlash: dssFlash,
                _aaveV3AddressProvider: aaveV3AddressProvider,
                _dai: dai
            })
        );
        flashloanAggregator = periphery.flashloanAggregator;

        setupCoreRegistry(address(hubCore.hubCoreRegistry), periphery);
        _setupAccessManager();
    }

    function _deployWormhole() internal returns (MockWormhole _wormhole) {
        _wormhole = new MockWormhole(WORMHOLE_HUB_CHAIN_ID, hubChainId);
    }

    function _deployHubCore() internal returns (Core_base.Base.HubCore memory deployment) {
        address accessManagerImplemAddr = address(new AccessManagerUpgradeable());
        deployment.accessManager = AccessManagerUpgradeable(
            address(
                new TransparentUpgradeableProxy(
                    accessManagerImplemAddr, dao, abi.encodeCall(AccessManagerUpgradeable.initialize, (deployer))
                )
            )
        );

        address oracleRegistryImplemAddr = address(new OracleRegistry());
        deployment.oracleRegistry = OracleRegistry(
            address(
                new TransparentUpgradeableProxy(
                    oracleRegistryImplemAddr,
                    dao,
                    abi.encodeCall(OracleRegistry.initialize, (address(deployment.accessManager)))
                )
            )
        );

        address tokenRegistryImplemAddr = address(new TokenRegistry());
        deployment.tokenRegistry = TokenRegistry(
            address(
                new TransparentUpgradeableProxy(
                    tokenRegistryImplemAddr,
                    dao,
                    abi.encodeCall(TokenRegistry.initialize, (address(deployment.accessManager)))
                )
            )
        );

        address chainRegistryImplemAddr = address(new ChainRegistry());
        deployment.chainRegistry = ChainRegistry(
            address(
                new TransparentUpgradeableProxy(
                    chainRegistryImplemAddr,
                    dao,
                    abi.encodeCall(ChainRegistry.initialize, (address(deployment.accessManager)))
                )
            )
        );

        address hubCoreRegistryImplemAddr = address(new HubCoreRegistry());
        deployment.hubCoreRegistry = HubCoreRegistry(
            address(
                new TransparentUpgradeableProxy(
                    hubCoreRegistryImplemAddr,
                    dao,
                    abi.encodeCall(
                        HubCoreRegistry.initialize,
                        (
                            address(deployment.oracleRegistry),
                            address(deployment.tokenRegistry),
                            address(deployment.chainRegistry),
                            address(deployment.accessManager)
                        )
                    )
                )
            )
        );

        address swapModuleImplemAddr = address(new SwapModule(address(deployment.hubCoreRegistry)));
        deployment.swapModule = SwapModule(
            address(
                new TransparentUpgradeableProxy(
                    swapModuleImplemAddr,
                    dao,
                    abi.encodeCall(SwapModule.initialize, (address(deployment.accessManager)))
                )
            )
        );

        address caliberImplemAddr = address(new Caliber(address(deployment.hubCoreRegistry), address(0)));
        deployment.caliberBeacon = new UpgradeableBeacon(caliberImplemAddr, dao);

        address machineImplemAddr = address(new Machine(address(deployment.hubCoreRegistry), address(wormhole)));
        deployment.machineBeacon = new UpgradeableBeacon(machineImplemAddr, dao);

        address preDepositVaultImplemAddr = address(new PreDepositVault(address(deployment.hubCoreRegistry)));
        deployment.preDepositVaultBeacon = new UpgradeableBeacon(preDepositVaultImplemAddr, dao);

        address hubCoreFactoryImplemAddr = address(new HubCoreFactory(address(deployment.hubCoreRegistry)));
        deployment.hubCoreFactory = HubCoreFactory(
            address(
                new TransparentUpgradeableProxy(
                    hubCoreFactoryImplemAddr,
                    dao,
                    abi.encodeCall(HubCoreFactory.initialize, (address(deployment.accessManager)))
                )
            )
        );

        deployment.hubCoreRegistry.setSwapModule(address(deployment.swapModule));
        deployment.hubCoreRegistry.setTokenRegistry(address(deployment.tokenRegistry));
        deployment.hubCoreRegistry.setChainRegistry(address(deployment.chainRegistry));
        deployment.hubCoreRegistry.setCoreFactory(address(deployment.hubCoreFactory));
        deployment.hubCoreRegistry.setCaliberBeacon(address(deployment.caliberBeacon));
        deployment.hubCoreRegistry.setMachineBeacon(address(deployment.machineBeacon));
        deployment.hubCoreRegistry.setPreDepositVaultBeacon(address(deployment.preDepositVaultBeacon));
    }

    function _setupAccessManager() internal {
        accessManager.grantRole(accessManager.ADMIN_ROLE(), dao, 0);
        accessManager.revokeRole(accessManager.ADMIN_ROLE(), address(this));
    }
}
