// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {MetaMorphoOracleFactory_Integration_Concrete_Test} from "../MetaMorphoOracleFactory.t.sol";

contract GetPrice_Integration_Concrete_Test is MetaMorphoOracleFactory_Integration_Concrete_Test {
    function test_GetPrice() public {
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
}
