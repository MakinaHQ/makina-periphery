// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {ERC4626Oracle} from "src/oracles/ERC4626Oracle.sol";

import {IMetaMorphoOracleFactory} from "src/interfaces/IMetaMorphoOracleFactory.sol";

import {MetaMorphoOracleFactory_Integration_Concrete_Test} from "../MetaMorphoOracleFactory.t.sol";

import {Errors} from "@makina-core/libraries/Errors.sol";

contract CreateMetaMorphoOracle_Integration_Concrete_Test is MetaMorphoOracleFactory_Integration_Concrete_Test {
    function test_RevertWhen_InvalidAddresses() public {
        vm.expectRevert(abi.encodeWithSelector(IMetaMorphoOracleFactory.NotFactory.selector));
        vm.prank(dao);
        metaMorphoOracleFactory.createMetaMorphoOracle(address(0), address(metaMorphoVault), oracleDecimals);

        vm.expectRevert(abi.encodeWithSelector(IMetaMorphoOracleFactory.NotMetaMorphoVault.selector));
        vm.prank(dao);
        metaMorphoOracleFactory.createMetaMorphoOracle(address(morphoVaultFactory), address(0), oracleDecimals);
    }

    function test_RevertWhen_OracleDecimalsLessThanUnderlyingAsset() public {
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidDecimals.selector));
        vm.prank(dao);
        metaMorphoOracleFactory.createMetaMorphoOracle(address(morphoVaultFactory), address(metaMorphoVault), 17);
    }

    function test_createMetaMorphoOracle_OracleDecimalsGreaterThanUnderlyingAsset() public {
        vm.prank(dao);
        ERC4626Oracle oracle1 = ERC4626Oracle(
            metaMorphoOracleFactory.createMetaMorphoOracle(address(morphoVaultFactory), address(metaMorphoVault), 19)
        );
        assertEq(oracle1.decimals(), 19);
    }

    function test_createMetaMorphoOracle_OracleDecimalsEqualToUnderlyingAsset() public {
        vm.prank(dao);
        ERC4626Oracle oracle2 = ERC4626Oracle(
            metaMorphoOracleFactory.createMetaMorphoOracle(address(morphoVaultFactory), address(metaMorphoVault), 18)
        );
        assertEq(oracle2.decimals(), 18);
        assertEq(oracle2.latestAnswer(), int256(10 ** 18));
    }
}
