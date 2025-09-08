// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {MockERC4626} from "@makina-core-test/mocks/MockERC4626.sol";

import {ERC4626Oracle} from "src/oracles/ERC4626Oracle.sol";
import {MockMetaMorphoFactory} from "test/mocks/MockMetaMorphoFactory.sol";

import {Integration_Concrete_Test} from "../IntegrationConcrete.t.sol";

abstract contract MetaMorphoOracleFactory_Integration_Concrete_Test is Integration_Concrete_Test {
    ERC4626Oracle public oracle;
    MockMetaMorphoFactory public morphoVaultFactory;
    MockERC4626 public metaMorphoVault;
    uint8 public oracleDecimals;

    function setUp() public virtual override {
        Integration_Concrete_Test.setUp();

        // deploy an oracle through the factory
        morphoVaultFactory = new MockMetaMorphoFactory();
        metaMorphoVault = new MockERC4626("MetaMorphoVault", "MMV", IERC20(baseToken), 0);
        oracleDecimals = 18;

        vm.startPrank(dao);
        metaMorphoOracleFactory.setMorphoFactory(address(morphoVaultFactory), true);
        oracle = ERC4626Oracle(
            metaMorphoOracleFactory.createMetaMorphoOracle(
                address(morphoVaultFactory), address(metaMorphoVault), oracleDecimals
            )
        );
        vm.stopPrank();
    }
}
