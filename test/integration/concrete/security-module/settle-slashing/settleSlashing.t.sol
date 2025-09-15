// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {ISecurityModule} from "src/interfaces/ISecurityModule.sol";
import {CoreErrors} from "src/libraries/Errors.sol";

import {SecurityModule_Integration_Concrete_Test} from "../SecurityModule.t.sol";

contract SettleSlashing_Integration_Concrete_Test is SecurityModule_Integration_Concrete_Test {
    uint256 private machineShares;

    function setUp() public override {
        SecurityModule_Integration_Concrete_Test.setUp();

        // Deposit assets to the machine
        uint256 inputAssets = 3 * DEFAULT_MIN_BALANCE_AFTER_SLASH;
        deal(address(accountingToken), depositorAddr, inputAssets);
        vm.startPrank(depositorAddr);
        accountingToken.approve(address(machine), inputAssets);
        machineShares = machine.deposit(inputAssets, user1, 0);
        vm.stopPrank();
    }

    function test_RevertWhen_NotSC() public {
        vm.expectRevert(CoreErrors.UnauthorizedCaller.selector);
        securityModule.settleSlashing();
    }

    function test_Slash() public {
        // User1 locks machine shares
        uint256 sharesToLock = machineShares;
        vm.startPrank(user1);
        machineShare.approve(address(securityModule), sharesToLock);
        securityModule.lock(sharesToLock, user3, 0);
        vm.stopPrank();

        vm.prank(securityCouncil);
        securityModule.slash(machineShares / 3);

        vm.expectEmit(false, false, false, false, address(securityModule));
        emit ISecurityModule.SlashingSettled();
        vm.prank(securityCouncil);
        securityModule.settleSlashing();

        assertFalse(securityModule.slashingMode());
    }
}
