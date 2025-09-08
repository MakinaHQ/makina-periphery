// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Unit_Concrete_Test} from "../UnitConcrete.t.sol";
import {ERC4626Oracle} from "src/oracles/ERC4626Oracle.sol";
import {MockMetaMorphoFactory} from "test/mocks/MockMetaMorphoFactory.sol";
import {console} from "forge-std/console.sol";
import {MockERC4626} from "@makina-core-test/mocks/MockERC4626.sol";
import {ERC4626, ERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IMetaMorphoOracleFactory} from "src/interfaces/IMetaMorphoOracleFactory.sol";

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
        vm.prank(dao);
        metaMorphoOracleFactory.setMorphoFactory(address(morphoVaultFactory), true);
        vm.prank(dao);
        oracle = ERC4626Oracle(
            metaMorphoOracleFactory.createMetaMorphoOracle(
                address(morphoVaultFactory), address(metaMorphoVault), oracleDecimals
            )
        );
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

    function test_MetaMorphoOracleFactory_Create_Oracle_Invalid_Inputs() public {
        vm.expectRevert(abi.encodeWithSelector(IMetaMorphoOracleFactory.NotFactory.selector));
        vm.prank(dao);
        metaMorphoOracleFactory.createMetaMorphoOracle(address(0), address(metaMorphoVault), oracleDecimals);

        vm.expectRevert(abi.encodeWithSelector(IMetaMorphoOracleFactory.NotMetaMorphoVault.selector));
        vm.prank(dao);
        metaMorphoOracleFactory.createMetaMorphoOracle(address(morphoVaultFactory), address(0), oracleDecimals);
    }

    function test_ERC4626Oracle_Getters() public view {
        assertEq(oracle.version(), 1);
        assertEq(address(oracle.vault()), address(metaMorphoVault));
        assertEq(address(oracle.underlying()), address(baseToken));
        assertEq(oracle.decimals(), oracleDecimals);
        assertEq(oracle.description(), "MMV / BT");
        assertEq(oracle.ONE_SHARE(), 10 ** metaMorphoVault.decimals());
        // in the test, oracle_decimals (17) <= underlying_decimals (18)
        assertEq(oracle.SCALING_NUMERATOR(), 1);
        assertEq(oracle.SCALING_DENOMINATOR(), 10 ** (baseToken.decimals() - oracleDecimals));
        assertEq(oracle.latestAnswer(), int256(10 ** oracleDecimals));
        assertEq(oracle.latestTimestamp(), block.timestamp);
        assertEq(oracle.latestRound(), 1);
        assertEq(oracle.getAnswer(1), int256(10 ** oracleDecimals));
        assertEq(oracle.getTimestamp(1), block.timestamp);
    }

    function test_ERC4626Oracle_Price_Invariants() public view {
        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            oracle.latestRoundData();
        assertEq(roundId, 1);
        assertEq(answer, int256(10 ** oracleDecimals));
        assertEq(startedAt, block.timestamp);
        assertEq(updatedAt, block.timestamp);
        assertEq(answeredInRound, 1);

        (roundId, answer, startedAt, updatedAt, answeredInRound) = oracle.getRoundData(1);
        assertEq(roundId, 1);
        assertEq(answer, int256(10 ** oracleDecimals));
        assertEq(startedAt, block.timestamp);
        assertEq(updatedAt, block.timestamp);
        assertEq(answeredInRound, 1);
    }

    function test_ERC4626Oracle_Price() public {
        // initial price should be 10 ** oracleDecimals
        assertEq(oracle.getPrice(), 10 ** oracleDecimals);

        // simulate deposits of assets into the vault
        baseToken.mint(address(this), 1_000_000 * 10 ** baseToken.decimals());
        baseToken.approve(address(metaMorphoVault), type(uint256).max);
        metaMorphoVault.deposit(1_000_000 * 10 ** baseToken.decimals(), address(this));
        // price should still be 10 ** oracleDecimals
        assertEq(oracle.getPrice(), 10 ** oracleDecimals);

        // simulate withdrawals of assets from the vault
        uint256 balanceToRedeem = metaMorphoVault.balanceOf(address(this)) / 2;
        metaMorphoVault.redeem(balanceToRedeem, address(this), address(this));
        // price should still be 10 ** oracleDecimals
        assertEq(oracle.getPrice(), 10 ** oracleDecimals);

        // simulate some positive yield in the vault
        baseToken.mint(address(metaMorphoVault), 100_000 * 10 ** baseToken.decimals());
        // price should have increased, slightly
        assertGt(oracle.getPrice(), 10 ** oracleDecimals);
        assertLt(oracle.getPrice(), 10 ** (oracleDecimals + 1));

        // simulate some negative yield in the vault, bringing price under 10 ** oracleDecimals
        baseToken.burn(address(metaMorphoVault), 200_000 * 10 ** baseToken.decimals());
        // price should have decreased, below initial price
        assertLt(oracle.getPrice(), 10 ** oracleDecimals);
        assertGt(oracle.getPrice(), 10 ** (oracleDecimals - 1));
    }

    function test_ERC4626Oracle_Decimals() public {
        // deploy an oracle with decimals = 0
        // then the decimals of the oracle should be that of the `asset` of the vault
        vm.expectRevert(abi.encodeWithSelector(ERC4626Oracle.LessDecimals.selector));
        vm.prank(dao);
        ERC4626Oracle oracle0 = ERC4626Oracle(
            metaMorphoOracleFactory.createMetaMorphoOracle(address(morphoVaultFactory), address(metaMorphoVault), 0)
        );

        // deploy an oracle with decimals > underlying.decimals
        vm.prank(dao);
        ERC4626Oracle oracle1 = ERC4626Oracle(
            metaMorphoOracleFactory.createMetaMorphoOracle(address(morphoVaultFactory), address(metaMorphoVault), 19)
        );
        assertEq(oracle1.decimals(), 19);
    }
}
