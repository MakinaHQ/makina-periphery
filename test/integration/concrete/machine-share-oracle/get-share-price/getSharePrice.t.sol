// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {DecimalsUtils} from "@makina-core/libraries/DecimalsUtils.sol";
import {MockPriceFeed} from "@makina-core-test/mocks/MockPriceFeed.sol";

import {MachineShareOracle} from "src/oracles/MachineShareOracle.sol";

import {MachineShareOracle_Integration_Concrete_Test} from "../MachineShareOracle.t.sol";

contract GetSharePrice_Integration_Concrete_Test is MachineShareOracle_Integration_Concrete_Test {
    uint256 public price_b_a;

    function setUp() public override {
        MachineShareOracle_Integration_Concrete_Test.setUp();

        bPriceFeed1 = new MockPriceFeed(18, 2e18, block.timestamp);

        vm.prank(dao);
        oracleRegistry.setFeedRoute(address(baseToken), address(bPriceFeed1), DEFAULT_PF_STALE_THRSHLD, address(0), 0);

        price_b_a = 2;
    }

    modifier withLiquidity() {
        uint256 depositAmount = 1e20;
        deal(address(baseToken), address(this), depositAmount);
        baseToken.approve(address(preDepositVault), depositAmount);
        preDepositVault.deposit(depositAmount, address(this), 0);
        _;
    }

    function test_GetSharePrice_PDVNotMigrated_UnderlyingDecimals_EmptyVault() public {
        vm.prank(dao);
        machineShareOracle =
            MachineShareOracle(machineShareOracleFactory.createMachineShareOracle(address(preDepositVault), atDecimals));

        uint256 vaultSharePrice = preDepositVault.previewRedeem(DecimalsUtils.SHARE_TOKEN_UNIT);
        uint256 oracleSharePrice = machineShareOracle.getSharePrice();
        assertEq(oracleSharePrice, price_b_a * vaultSharePrice);
    }

    function test_GetSharePrice_PDVNotMigrated_UnderlyingDecimals_NonEmptyVault() public withLiquidity {
        vm.prank(dao);
        machineShareOracle =
            MachineShareOracle(machineShareOracleFactory.createMachineShareOracle(address(preDepositVault), atDecimals));

        uint256 vaultSharePrice = preDepositVault.previewRedeem(DecimalsUtils.SHARE_TOKEN_UNIT);
        uint256 oracleSharePrice = machineShareOracle.getSharePrice();
        assertEq(oracleSharePrice, price_b_a * vaultSharePrice);
    }

    function test_GetSharePrice_PDVNotMigrated_HigherOracleDecimals_EmptyVault() public {
        vm.prank(dao);
        machineShareOracle = MachineShareOracle(
            machineShareOracleFactory.createMachineShareOracle(address(preDepositVault), atDecimals + 4)
        );

        uint256 vaultSharePrice = preDepositVault.previewRedeem(DecimalsUtils.SHARE_TOKEN_UNIT);
        uint256 oracleSharePrice = machineShareOracle.getSharePrice();
        assertEq(oracleSharePrice, (10 ** 4) * price_b_a * vaultSharePrice);
    }

    function test_GetSharePrice_PDVNotMigrated_HigherOracleDecimals_NonEmptyVault() public withLiquidity {
        vm.prank(dao);
        machineShareOracle = MachineShareOracle(
            machineShareOracleFactory.createMachineShareOracle(address(preDepositVault), atDecimals + 4)
        );

        uint256 vaultSharePrice = preDepositVault.previewRedeem(DecimalsUtils.SHARE_TOKEN_UNIT);
        uint256 oracleSharePrice = machineShareOracle.getSharePrice();
        assertEq(oracleSharePrice, (10 ** 4) * price_b_a * vaultSharePrice);
    }

    function test_GetSharePrice_PDVMigrated_UnderlyingDecimals_EmptyVault() public {
        vm.prank(dao);
        machineShareOracle =
            MachineShareOracle(machineShareOracleFactory.createMachineShareOracle(address(preDepositVault), atDecimals));

        (machine,) =
            _deployMachineFromPreDeposit(address(preDepositVault), address(this), address(this), address(feeManager));

        uint256 vaultSharePrice = machine.convertToAssets(DecimalsUtils.SHARE_TOKEN_UNIT);
        uint256 oracleSharePrice = machineShareOracle.getSharePrice();
        assertEq(oracleSharePrice, vaultSharePrice);

        // notify migration
        machineShareOracle.notifyPdvMigration();

        oracleSharePrice = machineShareOracle.getSharePrice();
        assertEq(oracleSharePrice, vaultSharePrice);
    }

    function test_GetSharePrice_PDVMigrated_UnderlyingDecimals_NonEmptyVault() public withLiquidity {
        vm.prank(dao);
        machineShareOracle =
            MachineShareOracle(machineShareOracleFactory.createMachineShareOracle(address(preDepositVault), atDecimals));

        (machine,) =
            _deployMachineFromPreDeposit(address(preDepositVault), address(this), address(this), address(feeManager));

        uint256 vaultSharePrice = machine.convertToAssets(DecimalsUtils.SHARE_TOKEN_UNIT);
        uint256 oracleSharePrice = machineShareOracle.getSharePrice();
        assertEq(oracleSharePrice, vaultSharePrice);

        // notify migration
        machineShareOracle.notifyPdvMigration();

        oracleSharePrice = machineShareOracle.getSharePrice();
        assertEq(oracleSharePrice, vaultSharePrice);
    }

    function test_GetSharePrice_PDVMigrated_HigherOracleDecimals_EmptyVault() public {
        vm.prank(dao);
        machineShareOracle = MachineShareOracle(
            machineShareOracleFactory.createMachineShareOracle(address(preDepositVault), atDecimals + 4)
        );

        (machine,) =
            _deployMachineFromPreDeposit(address(preDepositVault), address(this), address(this), address(feeManager));

        uint256 vaultSharePrice = machine.convertToAssets(DecimalsUtils.SHARE_TOKEN_UNIT);
        uint256 oracleSharePrice = machineShareOracle.getSharePrice();
        assertEq(oracleSharePrice, (10 ** 4) * vaultSharePrice);

        // notify migration
        machineShareOracle.notifyPdvMigration();

        oracleSharePrice = machineShareOracle.getSharePrice();
        assertEq(oracleSharePrice, (10 ** 4) * vaultSharePrice);
    }

    function test_GetSharePrice_PDVMigrated_HigherOracleDecimals_NonEmptyVault() public withLiquidity {
        vm.prank(dao);
        machineShareOracle = MachineShareOracle(
            machineShareOracleFactory.createMachineShareOracle(address(preDepositVault), atDecimals + 4)
        );

        (machine,) =
            _deployMachineFromPreDeposit(address(preDepositVault), address(this), address(this), address(feeManager));

        uint256 vaultSharePrice = machine.convertToAssets(DecimalsUtils.SHARE_TOKEN_UNIT);
        uint256 oracleSharePrice = machineShareOracle.getSharePrice();
        assertEq(oracleSharePrice, (10 ** 4) * vaultSharePrice);

        // notify migration
        machineShareOracle.notifyPdvMigration();

        oracleSharePrice = machineShareOracle.getSharePrice();
        assertEq(oracleSharePrice, (10 ** 4) * vaultSharePrice);
    }

    function test_GetSharePrice_Machine_UnderlyingDecimals_EmptyVault() public withPdvMigrated {
        vm.prank(dao);
        machineShareOracle =
            MachineShareOracle(machineShareOracleFactory.createMachineShareOracle(address(machine), atDecimals));

        uint256 vaultSharePrice = machine.convertToAssets(DecimalsUtils.SHARE_TOKEN_UNIT);
        uint256 oracleSharePrice = machineShareOracle.getSharePrice();
        assertEq(oracleSharePrice, vaultSharePrice);
    }

    function test_GetSharePrice_Machine_UnderlyingDecimals_NonEmptyVault() public withLiquidity withPdvMigrated {
        vm.prank(dao);
        machineShareOracle =
            MachineShareOracle(machineShareOracleFactory.createMachineShareOracle(address(machine), atDecimals));

        uint256 vaultSharePrice = machine.convertToAssets(DecimalsUtils.SHARE_TOKEN_UNIT);
        uint256 oracleSharePrice = machineShareOracle.getSharePrice();
        assertEq(oracleSharePrice, vaultSharePrice);
    }

    function test_GetSharePrice_Machine_HigherOracleDecimals_EmptyVault() public withPdvMigrated {
        vm.prank(dao);
        machineShareOracle =
            MachineShareOracle(machineShareOracleFactory.createMachineShareOracle(address(machine), atDecimals + 4));

        uint256 vaultSharePrice = machine.convertToAssets(DecimalsUtils.SHARE_TOKEN_UNIT);
        uint256 oracleSharePrice = machineShareOracle.getSharePrice();
        assertEq(oracleSharePrice, (10 ** 4) * vaultSharePrice);
    }

    function test_GetSharePrice_Machine_HigherOracleDecimals_NonEmptyVault() public withLiquidity withPdvMigrated {
        vm.prank(dao);
        machineShareOracle =
            MachineShareOracle(machineShareOracleFactory.createMachineShareOracle(address(machine), atDecimals + 4));

        uint256 vaultSharePrice = machine.convertToAssets(DecimalsUtils.SHARE_TOKEN_UNIT);
        uint256 oracleSharePrice = machineShareOracle.getSharePrice();
        assertEq(oracleSharePrice, (10 ** 4) * vaultSharePrice);
    }
}
