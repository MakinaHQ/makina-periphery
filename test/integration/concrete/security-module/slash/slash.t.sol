// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {ISecurityModule} from "src/interfaces/ISecurityModule.sol";
import {Errors, CoreErrors} from "src/libraries/Errors.sol";

import {SecurityModule_Integration_Concrete_Test} from "../SecurityModule.t.sol";

contract Slash_Integration_Concrete_Test is SecurityModule_Integration_Concrete_Test {
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
        securityModule.slash(0);
    }

    function test_RevertWhen_AmountExceedsMaxSlashable() public {
        // totalLocked is 0
        vm.expectRevert(Errors.MaxSlashableExceeded.selector);
        vm.prank(securityCouncil);
        securityModule.slash(1);

        // User1 locks machine shares
        uint256 sharesToLock = DEFAULT_MIN_BALANCE_AFTER_SLASH - 1;
        vm.startPrank(user1);
        machineShare.approve(address(securityModule), sharesToLock);
        securityModule.lock(sharesToLock, user3, 0);
        vm.stopPrank();

        // totalLocked < minBalanceAfterSlash
        vm.expectRevert(Errors.MaxSlashableExceeded.selector);
        vm.prank(securityCouncil);
        securityModule.slash(1);

        // User1 locks machine shares
        sharesToLock = 1;
        vm.startPrank(user1);
        machineShare.approve(address(securityModule), sharesToLock);
        securityModule.lock(sharesToLock, user3, 0);
        vm.stopPrank();

        // totalLocked = minBalanceAfterSlash
        vm.expectRevert(Errors.MaxSlashableExceeded.selector);
        vm.prank(securityCouncil);
        securityModule.slash(1);

        // User1 locks machine shares
        sharesToLock = 1;
        vm.startPrank(user1);
        machineShare.approve(address(securityModule), sharesToLock);
        securityModule.lock(sharesToLock, user3, 0);
        vm.stopPrank();

        // slash amount makes vault balance fall below minBalanceAfterSlash
        vm.expectRevert(Errors.MaxSlashableExceeded.selector);
        vm.prank(securityCouncil);
        securityModule.slash(2);

        // User1 locks machine shares
        sharesToLock = machineShare.balanceOf(user1);
        vm.startPrank(user1);
        machineShare.approve(address(securityModule), sharesToLock);
        securityModule.lock(sharesToLock, user3, 0);
        vm.stopPrank();

        // slash amount exceeds max allowed percentage
        uint256 slashAmount = (securityModule.totalLockedAmount() * DEFAULT_MAX_SLASHABLE_BPS / 10_000) + 1;
        vm.expectRevert(Errors.MaxSlashableExceeded.selector);
        vm.prank(securityCouncil);
        securityModule.slash(slashAmount);

        // slash amount = max allowed percentage
        // should not revert
        slashAmount = (securityModule.totalLockedAmount() * DEFAULT_MAX_SLASHABLE_BPS / 10_000);
        vm.prank(securityCouncil);
        securityModule.slash(slashAmount);
    }

    function test_Slash() public {
        // User1 locks machine shares
        uint256 sharesToLock = machineShares;
        vm.startPrank(user1);
        machineShare.approve(address(securityModule), sharesToLock);
        securityModule.lock(sharesToLock, user3, 0);
        vm.stopPrank();

        uint256 slashAmount = machineShares / 3;

        uint256 rateBefore = securityModule.convertToAssets(1e18);

        vm.expectEmit(false, false, false, true, address(securityModule));
        emit ISecurityModule.Slash(slashAmount);
        vm.prank(securityCouncil);
        securityModule.slash(slashAmount);

        assertEq(securityModule.totalLockedAmount(), machineShares - slashAmount);
        assertEq(machineShare.totalSupply(), machineShares - slashAmount);
        assertTrue(securityModule.slashingMode());
        assertLt(securityModule.convertToAssets(1e18), rateBefore);
    }
}
