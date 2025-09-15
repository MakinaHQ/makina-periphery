// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {Machine} from "@makina-core/machine/Machine.sol";

import {ISecurityModule} from "src/interfaces/ISecurityModule.sol";
import {SecurityModule} from "src/security-module/SecurityModule.sol";
import {SMCooldownReceipt} from "src/security-module/SMCooldownReceipt.sol";

import {Unit_Concrete_Test} from "../UnitConcrete.t.sol";

abstract contract SMCooldownReceipt_Unit_Concrete_Test is Unit_Concrete_Test {
    SecurityModule public securityModule;
    SMCooldownReceipt public cooldownReceipt;

    function setUp() public virtual override {
        Unit_Concrete_Test.setUp();

        (Machine machine,) = _deployMachine(address(accountingToken), address(0), address(0), address(0));
        address machineShare = machine.shareToken();

        vm.prank(dao);
        securityModule = SecurityModule(
            hubPeripheryFactory.createSecurityModule(
                ISecurityModule.SecurityModuleInitParams({
                    machineShare: machineShare,
                    initialCooldownDuration: DEFAULT_COOLDOWN_DURATION,
                    initialMaxSlashableBps: DEFAULT_MAX_SLASHABLE_BPS,
                    initialMinBalanceAfterSlash: DEFAULT_MIN_BALANCE_AFTER_SLASH
                })
            )
        );
        cooldownReceipt = SMCooldownReceipt(securityModule.cooldownReceipt());
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

contract SMCooldownReceipt_Getters_Unit_Concrete_Test is SMCooldownReceipt_Unit_Concrete_Test {
    function test_Getters() public view {
        assertEq(cooldownReceipt.name(), "Makina Security Module Cooldown NFT");
        assertEq(cooldownReceipt.symbol(), "MakinaSMCooldownNFT");
        assertEq(cooldownReceipt.nextTokenId(), 1);
    }
}
