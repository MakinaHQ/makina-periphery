// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {IERC721Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

import {ISecurityModule} from "src/interfaces/ISecurityModule.sol";
import {Errors, CoreErrors} from "src/libraries/Errors.sol";

import {SecurityModule_Integration_Concrete_Test} from "../SecurityModule.t.sol";

contract Redeem_Integration_Concrete_Test is SecurityModule_Integration_Concrete_Test {
    function test_RevertWhen_NonExistentRequest() public {
        uint256 cooldownId = 1;
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, cooldownId));
        securityModule.redeem(cooldownId, 0);
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

        skip(securityModule.cooldownDuration());

        // User1 tries to claim assets
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721IncorrectOwner.selector, user1, cooldownId, user3));
        securityModule.redeem(cooldownId, 0);
    }

    function test_RevertGiven_CooldownOngoing() public {
        uint256 inputAssets1 = 1e18;

        // Deposit assets to the machine
        deal(address(accountingToken), depositorAddr, inputAssets1);
        vm.startPrank(depositorAddr);
        accountingToken.approve(address(machine), inputAssets1);
        uint256 machineShares1 = machine.deposit(inputAssets1, user1, 0);
        vm.stopPrank();

        // User1 locks machine shares
        vm.startPrank(user1);
        machineShare.approve(address(securityModule), machineShares1);
        uint256 securityShares1 = securityModule.lock(machineShares1, user3, 0);
        vm.stopPrank();

        uint256 securitySharesToRedeem = securityShares1 / 2;

        // User3 starts cooldown
        vm.prank(user3);
        (uint256 cooldownId,,) = securityModule.startCooldown(securitySharesToRedeem, user3);

        skip(securityModule.cooldownDuration() - 1);

        vm.expectRevert(Errors.CooldownOngoing.selector);
        vm.prank(user3);
        securityModule.redeem(cooldownId, 0);
    }

    function test_RevertGiven_SlippageProtectionTriggered() public {
        uint256 inputAssets1 = 1e18;

        // Deposit assets to the machine
        deal(address(accountingToken), depositorAddr, inputAssets1);
        vm.startPrank(depositorAddr);
        accountingToken.approve(address(machine), inputAssets1);
        uint256 machineShares1 = machine.deposit(inputAssets1, user1, 0);
        vm.stopPrank();

        // User1 locks machine shares
        vm.startPrank(user1);
        machineShare.approve(address(securityModule), machineShares1);
        uint256 securityShares1 = securityModule.lock(machineShares1, user3, 0);
        vm.stopPrank();

        uint256 securitySharesToRedeem = securityShares1 / 2;

        // User3 starts cooldown
        vm.prank(user3);
        (uint256 cooldownId,,) = securityModule.startCooldown(securitySharesToRedeem, user3);

        skip(securityModule.cooldownDuration());

        uint256 expectedMachineShares = securityModule.convertToAssets(securitySharesToRedeem);

        vm.expectRevert(CoreErrors.SlippageProtection.selector);
        vm.prank(user3);
        securityModule.redeem(cooldownId, expectedMachineShares + 1);
    }

    function test_Redeem() public {
        uint256 inputAssets1 = 1e18;

        // Deposit assets to the machine
        deal(address(accountingToken), depositorAddr, inputAssets1);
        vm.startPrank(depositorAddr);
        accountingToken.approve(address(machine), inputAssets1);
        uint256 machineShares1 = machine.deposit(inputAssets1, user1, 0);
        vm.stopPrank();

        // User1 locks machine shares
        vm.startPrank(user1);
        machineShare.approve(address(securityModule), machineShares1);
        uint256 securityShares1 = securityModule.lock(machineShares1, user3, 0);
        vm.stopPrank();

        uint256 securitySharesToRedeem = securityShares1 / 2;

        // User3 starts cooldown and designates user4 as the receiver
        vm.prank(user3);
        (uint256 cooldownId,,) = securityModule.startCooldown(securitySharesToRedeem, user4);

        skip(securityModule.cooldownDuration());

        uint256 expectedMachineShares = securityModule.convertToAssets(securitySharesToRedeem);

        // User4 redeems security shares
        vm.expectEmit(true, true, false, true, address(securityModule));
        emit ISecurityModule.Redeem(cooldownId, user4, expectedMachineShares, securitySharesToRedeem);
        vm.prank(user4);
        securityModule.redeem(cooldownId, expectedMachineShares);

        assertEq(securityModule.balanceOf(user3), securityShares1 - securitySharesToRedeem);
        assertEq(machineShare.balanceOf(user4), expectedMachineShares);
        assertEq(cooldownReceipt.balanceOf(user4), 0);

        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, cooldownId));
        securityModule.pendingCooldown(cooldownId);
    }

    function test_Redeem_PositiveYield() public {
        uint256 inputAssets1 = 1e18;
        uint256 yieldAmount = 2e17;

        // Deposit assets to the machine
        deal(address(accountingToken), depositorAddr, inputAssets1);
        vm.startPrank(depositorAddr);
        accountingToken.approve(address(machine), inputAssets1);
        uint256 machineShares1 = machine.deposit(inputAssets1, user1, 0);
        vm.stopPrank();

        // User1 locks machine shares
        vm.startPrank(user1);
        machineShare.approve(address(securityModule), machineShares1);
        uint256 securityShares1 = securityModule.lock(machineShares1, user3, 0);
        vm.stopPrank();

        uint256 securitySharesToRedeem = securityShares1 / 2;

        // User3 starts cooldown and designates user4 as the receiver
        vm.prank(user3);
        (uint256 cooldownId,,) = securityModule.startCooldown(securitySharesToRedeem, user4);

        skip(securityModule.cooldownDuration());

        // get rate before yield
        uint256 expectedMachineShares = securityModule.convertToAssets(securitySharesToRedeem);

        // generate positive yield
        deal(address(machineShare), address(securityModule), machineShares1 + yieldAmount);

        // User4 redeems security shares
        vm.expectEmit(true, true, false, true, address(securityModule));
        emit ISecurityModule.Redeem(cooldownId, user4, expectedMachineShares, securitySharesToRedeem);
        vm.prank(user4);
        securityModule.redeem(cooldownId, expectedMachineShares);

        assertEq(securityModule.balanceOf(user3), securityShares1 - securitySharesToRedeem);
        assertEq(machineShare.balanceOf(user4), expectedMachineShares);
        assertEq(cooldownReceipt.balanceOf(user4), 0);

        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, cooldownId));
        securityModule.pendingCooldown(cooldownId);
    }

    function test_Redeem_NegativeYield() public {
        uint256 inputAssets1 = 1e18;
        uint256 yieldAmount = 2e17;

        // Deposit assets to the machine
        deal(address(accountingToken), depositorAddr, inputAssets1);
        vm.startPrank(depositorAddr);
        accountingToken.approve(address(machine), inputAssets1);
        uint256 machineShares1 = machine.deposit(inputAssets1, user1, 0);
        vm.stopPrank();

        // User1 locks machine shares
        vm.startPrank(user1);
        machineShare.approve(address(securityModule), machineShares1);
        uint256 securityShares1 = securityModule.lock(machineShares1, user3, 0);
        vm.stopPrank();

        uint256 securitySharesToRedeem = securityShares1 / 2;

        // User3 starts cooldown and designates user4 as the receiver
        vm.prank(user3);
        (uint256 cooldownId,,) = securityModule.startCooldown(securitySharesToRedeem, user4);

        skip(securityModule.cooldownDuration());

        // generate negative yield
        deal(address(machineShare), address(securityModule), machineShares1 - yieldAmount);

        // get rate after yield
        uint256 expectedMachineShares = securityModule.convertToAssets(securitySharesToRedeem);

        // User4 redeems security shares
        vm.expectEmit(true, true, false, true, address(securityModule));
        emit ISecurityModule.Redeem(cooldownId, user4, expectedMachineShares, securitySharesToRedeem);
        vm.prank(user4);
        securityModule.redeem(cooldownId, expectedMachineShares);

        assertEq(securityModule.balanceOf(user3), securityShares1 - securitySharesToRedeem);
        assertEq(machineShare.balanceOf(user4), expectedMachineShares);
        assertEq(cooldownReceipt.balanceOf(user4), 0);

        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, cooldownId));
        securityModule.pendingCooldown(cooldownId);
    }

    function test_Redeem_TwoUsers() public {
        uint256 inputAssets1 = 1e18;
        uint256 inputAssets2 = 2e18;

        uint256 yieldAmount = 2e17;

        uint256 usersDelay = 1 hours;

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

        // User2 locks machine shares
        vm.startPrank(user2);
        machineShare.approve(address(securityModule), machineShares2);
        uint256 securityShares2 = securityModule.lock(machineShares2, user2, 0);
        vm.stopPrank();

        // User1 starts cooldown
        vm.prank(user1);
        (uint256 cooldownId1,,) = securityModule.startCooldown(securityShares1, user1);
        uint256 previewRedeem1 = securityModule.previewLock(securityShares1);

        skip(usersDelay);

        // generate positive yield
        deal(address(machineShare), address(securityModule), machineShares1 + machineShares2 + yieldAmount);

        // User2 starts cooldown and designates user4 as the receiver
        vm.prank(user2);
        (uint256 cooldownId4,,) = securityModule.startCooldown(securityShares2, user4);

        // generate negative yield
        deal(address(machineShare), address(securityModule), machineShares1 + machineShares2);

        uint256 previewRedeem2 = securityModule.previewLock(securityShares2);

        skip(securityModule.cooldownDuration() - usersDelay);

        // User1 redeems security shares
        vm.expectEmit(true, true, false, true, address(securityModule));
        emit ISecurityModule.Redeem(cooldownId1, user1, previewRedeem1, securityShares1);
        vm.prank(user1);
        securityModule.redeem(cooldownId1, 0);

        assertEq(securityModule.balanceOf(user1), 0);
        assertEq(machineShare.balanceOf(user1), previewRedeem1);
        assertEq(cooldownReceipt.balanceOf(user1), 0);

        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, cooldownId1));
        securityModule.pendingCooldown(cooldownId1);

        // User4 tries redeeming security shares before cooldown maturity
        vm.expectRevert(Errors.CooldownOngoing.selector);
        vm.prank(user4);
        securityModule.redeem(cooldownId4, 0);

        skip(usersDelay);

        // User4 redeems security shares
        vm.expectEmit(true, true, false, true, address(securityModule));
        emit ISecurityModule.Redeem(cooldownId4, user4, previewRedeem2, securityShares2);
        vm.prank(user4);
        securityModule.redeem(cooldownId4, 0);

        assertEq(securityModule.balanceOf(user4), 0);
        assertEq(machineShare.balanceOf(user4), previewRedeem2);
        assertEq(cooldownReceipt.balanceOf(user4), 0);

        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, cooldownId4));
        securityModule.pendingCooldown(cooldownId4);
    }
}
