// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Machine} from "@makina-core/machine/Machine.sol";
import {MockFeeManager} from "@makina-core-test/mocks/MockFeeManager.sol";
import {PreDepositVault} from "@makina-core/pre-deposit/PreDepositVault.sol";

import {MachineShareOracle} from "src/oracles/MachineShareOracle.sol";

import {Integration_Concrete_Test} from "../IntegrationConcrete.t.sol";

abstract contract MachineShareOracle_Integration_Concrete_Test is Integration_Concrete_Test {
    MockFeeManager public feeManager;

    PreDepositVault public preDepositVault;
    Machine public machine;

    MachineShareOracle public machineShareOracle;

    uint8 public atDecimals;

    function setUp() public virtual override {
        Integration_Concrete_Test.setUp();

        atDecimals = accountingToken.decimals();

        feeManager = new MockFeeManager(dao, 0, 0);

        preDepositVault = _deployPreDepositVault(address(baseToken), address(accountingToken));
    }

    modifier withPdvMigrated() {
        (machine,) =
            _deployMachineFromPreDeposit(address(preDepositVault), address(this), address(this), address(feeManager));
        _;
    }
}
