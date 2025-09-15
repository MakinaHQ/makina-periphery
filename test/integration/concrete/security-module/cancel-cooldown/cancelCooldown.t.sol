// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {IERC721Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

import {Errors} from "src/libraries/Errors.sol";
import {ISecurityModule} from "src/interfaces/ISecurityModule.sol";

import {SecurityModule_Integration_Concrete_Test} from "../SecurityModule.t.sol";

contract CancelCooldown_Integration_Concrete_Test is SecurityModule_Integration_Concrete_Test {
    function test_RevertWhen_NonExistentRequest() public {
        uint256 cooldownId = 1;
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, cooldownId));
        securityModule.cancelCooldown(cooldownId);
    }

    function test_RevertWhen_IncorrectOwner() public {
        uint256 inputAssets = 1e18;

        // Deposit assets to the machine
        deal(address(accountingToken), depositorAddr, inputAssets);
        vm.startPrank(depositorAddr);
        accountingToken.approve(address(machine), inputAssets);
        uint256 machineShares = machine.deposit(inputAssets, user1, 0);
        vm.stopPrank();

        // User1 locks machine shares
        vm.startPrank(user1);
        machineShare.approve(address(securityModule), machineShares);
        uint256 securityShares = securityModule.lock(machineShares, user1, 0);

        uint256 securitySharesToRedeem = securityShares / 2;

        // User1 starts cooldown and designates user3 as the receiver
        (uint256 cooldownId,,) = securityModule.startCooldown(securitySharesToRedeem, user3);

        // User1 tries to claim assets
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721IncorrectOwner.selector, user1, cooldownId, user3));
        securityModule.cancelCooldown(cooldownId);
    }

    function test_RevertGiven_CooldownExpired() public {
        uint256 inputAssets = 1e18;

        // Deposit assets to the machine
        deal(address(accountingToken), depositorAddr, inputAssets);
        vm.startPrank(depositorAddr);
        accountingToken.approve(address(machine), inputAssets);
        uint256 machineShares = machine.deposit(inputAssets, user1, 0);
        vm.stopPrank();

        // User1 locks machine shares
        vm.startPrank(user1);
        machineShare.approve(address(securityModule), machineShares);
        uint256 securityShares = securityModule.lock(machineShares, user1, 0);

        uint256 securitySharesToRedeem = securityShares / 2;
        uint256 expectedCDMaturity = block.timestamp + securityModule.cooldownDuration();

        // User1 starts cooldown
        (uint256 cooldownId,,) = securityModule.startCooldown(securitySharesToRedeem, user3);
        vm.stopPrank();

        skip(expectedCDMaturity);

        // User3 tries to cancel cooldown after it has expired
        vm.prank(user3);
        vm.expectRevert(Errors.CooldownExpired.selector);
        securityModule.cancelCooldown(cooldownId);
    }

    function test_CancelCooldown() public {
        uint256 inputAssets = 1e18;

        // Deposit assets to the machine
        deal(address(accountingToken), depositorAddr, inputAssets);
        vm.startPrank(depositorAddr);
        accountingToken.approve(address(machine), inputAssets);
        uint256 machineShares = machine.deposit(inputAssets, user1, 0);
        vm.stopPrank();

        // User1 locks machine shares
        vm.startPrank(user1);
        machineShare.approve(address(securityModule), machineShares);
        uint256 securityShares = securityModule.lock(machineShares, user3, 0);
        vm.stopPrank();

        uint256 securitySharesToRedeem = securityShares / 2;

        // User3 starts cooldown and designates user4 as the receiver
        vm.prank(user3);
        (uint256 cooldownId,,) = securityModule.startCooldown(securitySharesToRedeem, user4);

        // User4 cancels cooldown
        vm.prank(user4);
        vm.expectEmit(true, true, false, true, address(securityModule));
        emit ISecurityModule.CooldownCancelled(cooldownId, user4, securitySharesToRedeem);
        securityModule.cancelCooldown(cooldownId);

        assertEq(securityModule.balanceOf(user3), securityShares - securitySharesToRedeem);
        assertEq(securityModule.balanceOf(user4), securitySharesToRedeem);
        assertEq(securityModule.balanceOf(address(securityModule)), 0);
        assertEq(cooldownReceipt.balanceOf(user4), 0);

        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, cooldownId));
        securityModule.pendingCooldown(cooldownId);
    }

    function test_CancelCooldown_TwoUsers() public {
        uint256 inputAssets1 = 1e18;
        uint256 inputAssets2 = 2e18;

        // Deposit assets to the machine
        deal(address(accountingToken), depositorAddr, inputAssets1 + inputAssets2);
        vm.startPrank(depositorAddr);
        accountingToken.approve(address(machine), inputAssets1 + inputAssets2);
        uint256 machineShares1 = machine.deposit(inputAssets1, user1, 0);
        uint256 machineShares2 = machine.deposit(inputAssets2, user2, 0);
        vm.stopPrank();

        // User1 locks machine shares
        vm.startPrank(user1);
        machineShare.approve(address(securityModule), machineShares1);
        uint256 securityShares1 = securityModule.lock(machineShares1, user1, 0);
        vm.stopPrank();

        uint256 securitySharesToRedeem1 = securityShares1 / 2;

        // User2 locks machine shares
        vm.startPrank(user2);
        machineShare.approve(address(securityModule), machineShares2);
        uint256 securityShares2 = securityModule.lock(machineShares2, user2, 0);
        vm.stopPrank();

        uint256 securitySharesToRedeem2 = securityShares2 / 2;
        uint256 expectedCDMaturity2 = block.timestamp + securityModule.cooldownDuration();

        // User1 starts cooldown
        vm.prank(user1);
        (uint256 cooldownId1,,) = securityModule.startCooldown(securitySharesToRedeem1, user1);

        // User2 starts cooldown and designates user4 as the receiver
        vm.prank(user2);
        (uint256 cooldownId4, uint256 maxAssets4,) = securityModule.startCooldown(securitySharesToRedeem2, user4);

        // User1 cancels cooldown
        vm.prank(user1);
        vm.expectEmit(true, true, false, true, address(securityModule));
        emit ISecurityModule.CooldownCancelled(cooldownId1, user1, securitySharesToRedeem1);
        securityModule.cancelCooldown(cooldownId1);

        assertEq(securityModule.balanceOf(user1), securityShares1);
        assertEq(securityModule.balanceOf(user2), securityShares2 - securitySharesToRedeem2);
        assertEq(securityModule.balanceOf(address(securityModule)), securitySharesToRedeem2);
        assertEq(cooldownReceipt.balanceOf(user1), 0);
        assertEq(cooldownReceipt.balanceOf(user4), 1);

        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, cooldownId1));
        securityModule.pendingCooldown(cooldownId1);

        (uint256 securitySharesCD4, uint256 currentExpectedAssets4, uint256 maturity4) =
            securityModule.pendingCooldown(cooldownId4);
        assertEq(securitySharesCD4, securitySharesToRedeem2);
        assertEq(currentExpectedAssets4, maxAssets4);
        assertEq(maturity4, expectedCDMaturity2);

        // User4 cancels cooldown
        vm.prank(user4);
        vm.expectEmit(true, true, false, true, address(securityModule));
        emit ISecurityModule.CooldownCancelled(cooldownId4, user4, securitySharesToRedeem2);
        securityModule.cancelCooldown(cooldownId4);

        assertEq(securityModule.balanceOf(user1), securityShares1);
        assertEq(securityModule.balanceOf(user2), securityShares2 - securitySharesToRedeem2);
        assertEq(securityModule.balanceOf(user4), securitySharesToRedeem2);
        assertEq(securityModule.balanceOf(address(securityModule)), 0);
        assertEq(cooldownReceipt.balanceOf(user4), 0);

        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, cooldownId4));
        securityModule.pendingCooldown(cooldownId4);
    }
}
