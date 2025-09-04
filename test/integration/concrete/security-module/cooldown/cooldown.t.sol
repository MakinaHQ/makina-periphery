// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {ISecurityModule} from "src/interfaces/ISecurityModule.sol";

import {SecurityModule_Integration_Concrete_Test} from "../SecurityModule.t.sol";

contract StartCooldown_Integration_Concrete_Test is SecurityModule_Integration_Concrete_Test {
    function test_StartCooldown() public {
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
        uint256 expectedCDMaturity = block.timestamp + securityModule.cooldownDuration();

        // User3 starts cooldown
        vm.prank(user3);
        vm.expectEmit(true, false, false, true, address(securityModule));
        emit ISecurityModule.Cooldown(user3, securitySharesToRedeem, expectedCDMaturity);
        securityModule.startCooldown(securitySharesToRedeem);

        (uint256 securitySharesCD, uint256 maturity) = securityModule.pendingCooldown(user3);

        assertEq(securitySharesCD, securitySharesToRedeem);
        assertEq(maturity, expectedCDMaturity);
    }

    function test_StartCooldown_Override() public {
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

        // User3 starts cooldown
        vm.startPrank(user3);
        uint256 expectedCDMaturity = block.timestamp + securityModule.cooldownDuration();
        uint256 securitySharesToRedeem = securityShares1 / 2;
        securityModule.startCooldown(securitySharesToRedeem);

        // User3 restarts cooldown with different amount
        securitySharesToRedeem--;
        vm.expectEmit(true, false, false, true, address(securityModule));
        emit ISecurityModule.Cooldown(user3, securitySharesToRedeem, expectedCDMaturity);
        securityModule.startCooldown(securitySharesToRedeem);

        (uint256 securitySharesCD, uint256 maturity) = securityModule.pendingCooldown(user3);

        assertEq(securitySharesCD, securitySharesToRedeem);
        assertEq(maturity, expectedCDMaturity);

        skip(1);

        // User3 restarts cooldown later
        expectedCDMaturity = block.timestamp + securityModule.cooldownDuration();
        vm.expectEmit(true, false, false, true, address(securityModule));
        emit ISecurityModule.Cooldown(user3, securitySharesToRedeem, expectedCDMaturity);
        securityModule.startCooldown(securitySharesToRedeem);

        (securitySharesCD, maturity) = securityModule.pendingCooldown(user3);

        assertEq(securitySharesCD, securitySharesToRedeem);
        assertEq(maturity, expectedCDMaturity);
    }
}
