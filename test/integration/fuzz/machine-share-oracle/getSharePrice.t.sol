// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {DecimalsUtils} from "@makina-core/libraries/DecimalsUtils.sol";
import {Machine} from "@makina-core/machine/Machine.sol";
import {MockERC20} from "@makina-core-test/mocks/MockERC20.sol";
import {MockFeeManager} from "@makina-core-test/mocks/MockFeeManager.sol";
import {MockPriceFeed} from "@makina-core-test/mocks/MockPriceFeed.sol";
import {PreDepositVault} from "@makina-core/pre-deposit/PreDepositVault.sol";

import {MachineShareOracle} from "src/oracles/MachineShareOracle.sol";

import {Base_Hub_Test} from "test/base/Base.t.sol";

contract GetSharePrice_Integration_Fuzz_Test is Base_Hub_Test {
    MockERC20 public accountingToken;
    MockERC20 public depositToken;

    MockPriceFeed internal aPriceFeed1;
    MockPriceFeed internal dPriceFeed1;

    MockFeeManager public feeManager;

    PreDepositVault public preDepositVault;
    Machine public machine;

    MachineShareOracle public machineShareOracle;

    /// a represents the accounting token
    /// d represents the deposit token
    /// e represents the reference currency of the oracle registry
    /// o represents the oracle
    struct Data {
        uint8 aDecimals;
        uint8 dDecimals;
        uint32 price_a_e;
        uint32 price_d_e;
        uint8 oDecimals;
        uint256 assetsToDeposit;
        uint256 yield;
        bool yieldDirection;
        uint256 shareTokensToRedeem;
    }

    function setUp() public override {
        Base_Hub_Test.setUp();

        feeManager = new MockFeeManager(dao, 0, 0);
    }

    function _fuzzTestSetupAfter(Data memory data) public {
        data.aDecimals = uint8(bound(data.aDecimals, 6, 18));
        data.dDecimals = uint8(bound(data.dDecimals, data.aDecimals, 18));
        data.price_a_e = uint32(bound(data.price_a_e, 3, 1e4));
        data.price_d_e = uint32(bound(data.price_d_e, data.price_a_e / 3, data.price_a_e * 3));
        data.oDecimals = uint8(bound(data.oDecimals, data.aDecimals, 18));

        aPriceFeed1 = new MockPriceFeed(18, int256(data.price_a_e * uint256(1e18)), block.timestamp);
        dPriceFeed1 = new MockPriceFeed(18, int256(data.price_d_e * uint256(1e18)), block.timestamp);

        accountingToken = new MockERC20("Accounting Token", "AT", data.aDecimals);
        depositToken = new MockERC20("Deposit Token", "DT", data.dDecimals);

        vm.startPrank(dao);
        oracleRegistry.setFeedRoute(address(accountingToken), address(aPriceFeed1), 2 hours, address(0), 0);
        oracleRegistry.setFeedRoute(address(depositToken), address(dPriceFeed1), 2 hours, address(0), 0);
        vm.stopPrank();

        preDepositVault = _deployPreDepositVault(address(depositToken), address(accountingToken));
    }

    function testFuzz_GetSharePrice_PDVNotMigrated(Data memory data) public {
        _fuzzTestSetupAfter(data);

        vm.prank(dao);
        machineShareOracle = MachineShareOracle(
            machineShareOracleFactory.createMachineShareOracle(address(preDepositVault), data.oDecimals)
        );

        _checkSharePrice_PDV(data);

        // deposit into PDV
        data.assetsToDeposit = bound(data.assetsToDeposit, (10 ** data.dDecimals), 1e25);
        depositToken.mint(address(this), data.assetsToDeposit);
        depositToken.approve(address(preDepositVault), data.assetsToDeposit);
        uint256 mintedShares = preDepositVault.deposit(data.assetsToDeposit, address(this), 0, 0);

        _checkSharePrice_PDV(data);

        // generate yield into PDV
        if (data.yieldDirection) {
            // increase price of deposit token
            data.yield = bound(data.yield, 0, 10 * data.price_d_e);
            data.price_d_e += uint32(data.yield);
        } else {
            // decrease price of deposit token
            data.yield = bound(data.yield, 0, 9 * data.price_d_e / 10);
            data.price_d_e -= uint32(data.yield);
        }
        dPriceFeed1.setLatestAnswer(int256(data.price_d_e * uint256(1e18)));

        _checkSharePrice_PDV(data);

        // redeem shares from PDV
        data.shareTokensToRedeem = bound(data.shareTokensToRedeem, 0, 99 * mintedShares / 100);
        preDepositVault.redeem(data.shareTokensToRedeem, address(this), 0);

        _checkSharePrice_PDV(data);
    }

    function testFuzz_GetSharePrice_PDVMigrated(Data memory data) public {
        _fuzzTestSetupAfter(data);

        vm.prank(dao);
        machineShareOracle = MachineShareOracle(
            machineShareOracleFactory.createMachineShareOracle(address(preDepositVault), data.oDecimals)
        );

        (machine,) =
            _deployMachineFromPreDeposit(address(preDepositVault), address(this), address(this), address(feeManager));

        _checkSharePrice_Machine(data);

        // deposit into Machine
        data.assetsToDeposit = bound(data.assetsToDeposit, 0, 1e30);
        accountingToken.mint(address(this), data.assetsToDeposit);
        accountingToken.approve(address(machine), data.assetsToDeposit);
        uint256 mintedShares = machine.deposit(data.assetsToDeposit, address(this), 0, 0);

        _checkSharePrice_Machine(data);

        // generate yield into Machine
        if (data.yieldDirection) {
            data.yield = bound(data.yield, 0, 1e20);
            accountingToken.mint(address(machine), data.yield);
        } else {
            data.yield = bound(data.yield, 0, data.assetsToDeposit);
            accountingToken.burn(address(machine), data.yield);
        }

        machine.updateTotalAum();

        _checkSharePrice_Machine(data);

        // redeem shares from Machine
        data.shareTokensToRedeem = bound(data.shareTokensToRedeem, 0, mintedShares);
        machine.redeem(data.shareTokensToRedeem, address(this), 0);

        _checkSharePrice_Machine(data);

        // notify migration to oracle
        machineShareOracle.notifyPdvMigration();

        _checkSharePrice_Machine(data);
    }

    function testFuzz_GetSharePrice_Machine(Data memory data) public {
        _fuzzTestSetupAfter(data);

        (machine,) =
            _deployMachineFromPreDeposit(address(preDepositVault), address(this), address(this), address(feeManager));

        vm.prank(dao);
        machineShareOracle =
            MachineShareOracle(machineShareOracleFactory.createMachineShareOracle(address(machine), data.oDecimals));

        _checkSharePrice_Machine(data);

        // deposit into Machine
        data.assetsToDeposit = bound(data.assetsToDeposit, 0, 1e30);
        accountingToken.mint(address(this), data.assetsToDeposit);
        accountingToken.approve(address(machine), data.assetsToDeposit);
        uint256 mintedShares = machine.deposit(data.assetsToDeposit, address(this), 0, 0);

        _checkSharePrice_Machine(data);

        // generate yield into Machine
        if (data.yieldDirection) {
            data.yield = bound(data.yield, 0, 1e20);
            accountingToken.mint(address(machine), data.yield);
        } else {
            data.yield = bound(data.yield, 0, data.assetsToDeposit);
            accountingToken.burn(address(machine), data.yield);
        }

        machine.updateTotalAum();

        _checkSharePrice_Machine(data);

        // redeem shares from Machine
        data.shareTokensToRedeem = bound(data.shareTokensToRedeem, 0, mintedShares);
        machine.redeem(data.shareTokensToRedeem, address(this), 0);

        _checkSharePrice_Machine(data);
    }

    function _checkSharePrice_PDV(Data memory data) internal view {
        uint256 vaultSharePrice = preDepositVault.previewRedeem(DecimalsUtils.SHARE_TOKEN_UNIT);
        uint256 adjustedVaultSharePrice = (
            vaultSharePrice * oracleRegistry.getPrice(address(depositToken), address(accountingToken))
                / (10 ** data.dDecimals)
        ) * (10 ** (data.oDecimals - data.aDecimals));

        uint256 oracleSharePrice = machineShareOracle.getSharePrice();

        assertApproxEqRel(oracleSharePrice, adjustedVaultSharePrice, 1e16);
        assertGe(oracleSharePrice, adjustedVaultSharePrice);
    }

    function _checkSharePrice_Machine(Data memory data) internal view {
        uint256 vaultSharePrice = machine.convertToAssets(DecimalsUtils.SHARE_TOKEN_UNIT);
        uint256 oracleSharePrice = machineShareOracle.getSharePrice();
        assertEq(oracleSharePrice, vaultSharePrice * (10 ** (data.oDecimals - data.aDecimals)));
    }
}
