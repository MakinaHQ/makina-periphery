// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {ISecurityModule} from "src/interfaces/ISecurityModule.sol";
import {Errors, CoreErrors} from "src/libraries/Errors.sol";

import {SecurityModule_Integration_Concrete_Test} from "../SecurityModule.t.sol";

contract Lock_Integration_Concrete_Test is SecurityModule_Integration_Concrete_Test {
    function test_RevertGiven_SlashingSettlementOngoing() public {
        vm.prank(securityCouncil);
        securityModule.slash(0);

        vm.expectRevert(Errors.SlashingSettlementOngoing.selector);
        securityModule.lock(0, address(0), 0);
    }

    function test_RevertGiven_SlippageProtectionTriggered() public {
        uint256 inputAssets1 = 1e18;

        // Deposit assets to the machine
        deal(address(accountingToken), depositorAddr, inputAssets1);
        vm.startPrank(depositorAddr);
        accountingToken.approve(address(machine), inputAssets1);
        uint256 shares1 = machine.deposit(inputAssets1, user1, 0);
        vm.stopPrank();

        uint256 previewLock = securityModule.previewLock(shares1);

        // User1 tries locking machine shares with slippage protection too high
        vm.startPrank(user1);
        machineShare.approve(address(securityModule), shares1);
        vm.expectRevert(CoreErrors.SlippageProtection.selector);
        securityModule.lock(shares1, user1, previewLock + 1);
    }

    function test_Lock() public {
        uint256 inputAssets1 = 1e18;

        // Deposit assets to the machine
        deal(address(accountingToken), depositorAddr, inputAssets1);
        vm.startPrank(depositorAddr);
        accountingToken.approve(address(machine), inputAssets1);
        uint256 machineShares1 = machine.deposit(inputAssets1, user1, 0);
        vm.stopPrank();

        uint256 previewLock = securityModule.previewLock(machineShares1);

        // User1 locks machine shares
        vm.startPrank(user1);
        machineShare.approve(address(securityModule), machineShares1);
        vm.expectEmit(true, true, false, true, address(securityModule));
        emit ISecurityModule.Lock(user1, user3, machineShares1, previewLock);
        securityModule.lock(machineShares1, user3, previewLock);
        vm.stopPrank();

        assertEq(machineShare.balanceOf(user1), 0);
        assertEq(machineShare.balanceOf(address(securityModule)), machineShares1);
        assertEq(securityModule.balanceOf(user3), previewLock);
        assertEq(securityModule.totalLockedAmount(), machineShares1);
    }
}
