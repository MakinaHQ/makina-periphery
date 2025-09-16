// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {MachineShare} from "@makina-core/machine/MachineShare.sol";

import {ISecurityModule} from "src/interfaces/ISecurityModule.sol";
import {SecurityModule} from "src/security-module/SecurityModule.sol";
import {SMCooldownReceipt} from "src/security-module/SMCooldownReceipt.sol";

import {MachinePeriphery_Integration_Concrete_Test} from "../machine-periphery/MachinePeriphery.t.sol";

abstract contract SecurityModule_Integration_Concrete_Test is MachinePeriphery_Integration_Concrete_Test {
    SecurityModule public securityModule;
    SMCooldownReceipt public cooldownReceipt;

    address public depositorAddr;

    function setUp() public virtual override {
        MachinePeriphery_Integration_Concrete_Test.setUp();

        depositorAddr = makeAddr("depositor");

        (machine,) = _deployMachine(address(accountingToken), depositorAddr, address(0), address(0));
        machineShare = MachineShare(machine.shareToken());

        vm.prank(dao);
        securityModule = SecurityModule(
            hubPeripheryFactory.createSecurityModule(
                ISecurityModule.SecurityModuleInitParams({
                    machineShare: address(machineShare),
                    initialCooldownDuration: DEFAULT_COOLDOWN_DURATION,
                    initialMaxSlashableBps: DEFAULT_MAX_SLASHABLE_BPS,
                    initialMinBalanceAfterSlash: DEFAULT_MIN_BALANCE_AFTER_SLASH
                })
            )
        );
        cooldownReceipt = SMCooldownReceipt(securityModule.cooldownReceipt());
    }
}
