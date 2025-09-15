// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Errors, CoreErrors} from "src/libraries/Errors.sol";
import {IAsyncRedeemer} from "src/interfaces/IAsyncRedeemer.sol";

import {AsyncRedeemer_Integration_Concrete_Test} from "../AsyncRedeemer.t.sol";

contract RequestRedeem_Integration_Concrete_Test is AsyncRedeemer_Integration_Concrete_Test {
    function test_RevertGiven_MachineNotSet() public {
        vm.expectRevert(Errors.MachineNotSet.selector);
        asyncRedeemer.requestRedeem(0, address(0));
    }

    function test_RevertWhen_UnauthorizedCaller_WithWhitelistEnabled()
        public
        withMachine(address(machine))
        withWhitelistEnabled
    {
        vm.expectRevert(CoreErrors.UnauthorizedCaller.selector);
        asyncRedeemer.requestRedeem(0, address(0));
    }

    function test_RequestRedeem() public withMachine(address(machine)) {
        uint256 assets1 = 1e18;
        uint256 assets2 = 2e18;

        uint256 _nextRequestId = asyncRedeemer.nextRequestId();

        // Deposit assets to the machine
        deal(address(accountingToken), depositorAddr, assets1 + assets2);
        vm.startPrank(depositorAddr);
        IERC20(accountingToken).approve(address(machine), assets1 + assets2);
        uint256 shares1 = machine.deposit(assets1, user1, 0);
        uint256 shares2 = machine.deposit(assets2, user2, 0);
        vm.stopPrank();

        // User1 enters queue
        vm.startPrank(user1);
        machineShare.approve(address(asyncRedeemer), shares1);
        vm.expectEmit(true, true, true, true, address(asyncRedeemer));
        emit IAsyncRedeemer.RedeemRequestCreated(_nextRequestId, shares1, user3);
        uint256 requestId1 = asyncRedeemer.requestRedeem(shares1, user3);
        vm.stopPrank();

        assertEq(asyncRedeemer.getShares(requestId1), shares1);
        assertEq(asyncRedeemer.lastFinalizedRequestId(), 0);

        assertEq(requestId1, _nextRequestId);
        assertEq(asyncRedeemer.nextRequestId(), ++_nextRequestId);

        assertEq(machineShare.balanceOf(user1), 0);
        assertEq(machineShare.balanceOf(address(asyncRedeemer)), shares1);
        assertEq(accountingToken.balanceOf(user1), 0);

        // User2 enters queue
        vm.startPrank(user2);
        machineShare.approve(address(asyncRedeemer), shares2);
        vm.expectEmit(true, true, true, true, address(asyncRedeemer));
        emit IAsyncRedeemer.RedeemRequestCreated(_nextRequestId, shares2, user4);
        uint256 requestId2 = asyncRedeemer.requestRedeem(shares2, user4);
        vm.stopPrank();

        assertEq(requestId2, _nextRequestId);
        assertEq(asyncRedeemer.nextRequestId(), ++_nextRequestId);

        assertEq(asyncRedeemer.getShares(requestId1), shares1);
        assertEq(asyncRedeemer.getShares(requestId2), shares2);
        assertEq(asyncRedeemer.lastFinalizedRequestId(), 0);

        assertEq(machineShare.balanceOf(user1), 0);
        assertEq(machineShare.balanceOf(address(asyncRedeemer)), shares1 + shares2);
        assertEq(accountingToken.balanceOf(user1), 0);

        assertEq(machineShare.balanceOf(user2), 0);
        assertEq(accountingToken.balanceOf(user2), 0);
    }

    function test_RequestRedeem_WithWhitelistEnabled()
        public
        withMachine(address(machine))
        withWhitelistEnabled
        withWhitelistedUser(user1)
        withWhitelistedUser(user2)
    {
        uint256 assets1 = 1e18;
        uint256 assets2 = 2e18;

        uint256 _nextRequestId = asyncRedeemer.nextRequestId();

        // Deposit assets to the machine
        deal(address(accountingToken), depositorAddr, assets1 + assets2);
        vm.startPrank(depositorAddr);
        IERC20(accountingToken).approve(address(machine), assets1 + assets2);
        uint256 shares1 = machine.deposit(assets1, user1, 0);
        uint256 shares2 = machine.deposit(assets2, user2, 0);
        vm.stopPrank();

        // User1 enters queue
        vm.startPrank(user1);
        machineShare.approve(address(asyncRedeemer), shares1);
        vm.expectEmit(true, true, true, true, address(asyncRedeemer));
        emit IAsyncRedeemer.RedeemRequestCreated(_nextRequestId, shares1, user3);
        uint256 requestId1 = asyncRedeemer.requestRedeem(shares1, user3);
        vm.stopPrank();

        assertEq(asyncRedeemer.getShares(requestId1), shares1);
        assertEq(asyncRedeemer.lastFinalizedRequestId(), 0);

        assertEq(requestId1, _nextRequestId);
        assertEq(asyncRedeemer.nextRequestId(), ++_nextRequestId);

        assertEq(machineShare.balanceOf(user1), 0);
        assertEq(machineShare.balanceOf(address(asyncRedeemer)), shares1);
        assertEq(accountingToken.balanceOf(user1), 0);

        // User2 enters queue
        vm.startPrank(user2);
        machineShare.approve(address(asyncRedeemer), shares2);
        vm.expectEmit(true, true, true, true, address(asyncRedeemer));
        emit IAsyncRedeemer.RedeemRequestCreated(_nextRequestId, shares2, user4);
        uint256 requestId2 = asyncRedeemer.requestRedeem(shares2, user4);
        vm.stopPrank();

        assertEq(requestId2, _nextRequestId);
        assertEq(asyncRedeemer.nextRequestId(), ++_nextRequestId);

        assertEq(asyncRedeemer.getShares(requestId1), shares1);
        assertEq(asyncRedeemer.getShares(requestId2), shares2);
        assertEq(asyncRedeemer.lastFinalizedRequestId(), 0);

        assertEq(machineShare.balanceOf(user1), 0);
        assertEq(machineShare.balanceOf(address(asyncRedeemer)), shares1 + shares2);
        assertEq(accountingToken.balanceOf(user1), 0);

        assertEq(machineShare.balanceOf(user2), 0);
        assertEq(accountingToken.balanceOf(user2), 0);
    }
}
