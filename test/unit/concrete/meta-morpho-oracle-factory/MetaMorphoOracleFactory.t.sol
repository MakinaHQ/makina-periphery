// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {MockERC4626} from "@makina-core-test/mocks/MockERC4626.sol";

import {ERC4626Oracle} from "src/oracles/ERC4626Oracle.sol";
import {MockMetaMorphoFactory} from "test/mocks/MockMetaMorphoFactory.sol";

import {Unit_Concrete_Test} from "../UnitConcrete.t.sol";

abstract contract MetaMorphoOracleFactory_Unit_Concrete_Test is Unit_Concrete_Test {
    ERC4626Oracle public oracle;
    MockMetaMorphoFactory public morphoVaultFactory;
    MockERC4626 public metaMorphoVault;
    uint8 public oracleDecimals;

    function setUp() public virtual override {
        Unit_Concrete_Test.setUp();

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

contract Getters_Setters_MetaMorphoOracleFactory_Unit_Concrete_Test is MetaMorphoOracleFactory_Unit_Concrete_Test {
    function test_Getters() public view {
        assertEq(metaMorphoOracleFactory.authority(), address(accessManager));
        assertTrue(metaMorphoOracleFactory.isMorphoFactory(address(morphoVaultFactory)));
        assertFalse(metaMorphoOracleFactory.isMorphoFactory(address(0)));
        assertTrue(metaMorphoOracleFactory.isOracle(address(oracle)));
        assertFalse(metaMorphoOracleFactory.isOracle(address(0)));
    }

    function test_ERC4626Oracle_Getters() public view {
        assertEq(oracle.version(), 1);
        assertEq(address(oracle.vault()), address(metaMorphoVault));
        assertEq(address(oracle.underlying()), address(baseToken));
        assertEq(oracle.decimals(), oracleDecimals);
        assertEq(oracle.description(), "MMV / BT");
        assertEq(oracle.ONE_SHARE(), 10 ** metaMorphoVault.decimals());
        assertEq(oracle.SCALING_NUMERATOR(), 1);
        assertEq(oracle.latestAnswer(), int256(10 ** oracleDecimals));
        assertEq(oracle.latestTimestamp(), block.timestamp);
        assertEq(oracle.latestRound(), 1);
        assertEq(oracle.getAnswer(1), int256(10 ** oracleDecimals));
        assertEq(oracle.getTimestamp(1), block.timestamp);
    }

    function test_ERC4626Oracle_Price_Invariants() public {
        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            oracle.latestRoundData();
        assertEq(roundId, 1);
        assertEq(answer, int256(10 ** oracleDecimals));
        assertEq(startedAt, block.timestamp);
        assertEq(updatedAt, block.timestamp);
        assertEq(answeredInRound, 1);

        skip(1 days);

        (roundId, answer, startedAt, updatedAt, answeredInRound) = oracle.getRoundData(1);
        assertEq(roundId, 1);
        assertEq(answer, int256(10 ** oracleDecimals));
        assertEq(startedAt, block.timestamp);
        assertEq(updatedAt, block.timestamp);
        assertEq(answeredInRound, 1);
    }
}
