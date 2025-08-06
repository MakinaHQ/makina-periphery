// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Errors} from "src/libraries/Errors.sol";
import {IAsyncMachineRedeemer} from "src/interfaces/IAsyncMachineRedeemer.sol";

import {AsyncMachineRedeemer_Integration_Concrete_Test} from "../AsyncMachineRedeemer.t.sol";

contract RequestRedeem_Integration_Concrete_Test is AsyncMachineRedeemer_Integration_Concrete_Test {
    function test_RevertGiven_MachineNotSet() public {
        vm.expectRevert(Errors.MachineNotSet.selector);
        asyncMachineRedeemer.requestRedeem(0, address(0));
    }

    function test_RequestRedeem() public withMachine(address(machine)) {
        uint256 assets1 = 1e18;
        uint256 assets2 = 2e18;

        uint256 _nextRequestId = asyncMachineRedeemer.nextRequestId();

        // Deposit assets to the machine
        deal(address(accountingToken), machineDepositorAddr, assets1 + assets2);
        vm.startPrank(machineDepositorAddr);
        IERC20(accountingToken).approve(address(machine), assets1 + assets2);
        uint256 shares1 = machine.deposit(assets1, user1, 0);
        uint256 shares2 = machine.deposit(assets2, user2, 0);
        vm.stopPrank();

        // User1 enters queue
        vm.startPrank(user1);
        machineShare.approve(address(asyncMachineRedeemer), shares1);
        vm.expectEmit(true, true, true, true, address(asyncMachineRedeemer));
        emit IAsyncMachineRedeemer.RedeemRequestCreated(_nextRequestId, shares1, user3);
        uint256 requestId1 = asyncMachineRedeemer.requestRedeem(shares1, user3);
        vm.stopPrank();

        assertEq(asyncMachineRedeemer.getShares(requestId1), shares1);
        assertEq(asyncMachineRedeemer.lastFinalizedRequestId(), 0);

        assertEq(requestId1, _nextRequestId);
        assertEq(asyncMachineRedeemer.nextRequestId(), ++_nextRequestId);

        assertEq(machineShare.balanceOf(user1), 0);
        assertEq(machineShare.balanceOf(address(asyncMachineRedeemer)), shares1);
        assertEq(accountingToken.balanceOf(user1), 0);

        // User2 enters queue
        vm.startPrank(user2);
        machineShare.approve(address(asyncMachineRedeemer), shares2);
        vm.expectEmit(true, true, true, true, address(asyncMachineRedeemer));
        emit IAsyncMachineRedeemer.RedeemRequestCreated(_nextRequestId, shares2, user4);
        uint256 requestId2 = asyncMachineRedeemer.requestRedeem(shares2, user4);
        vm.stopPrank();

        assertEq(requestId2, _nextRequestId);
        assertEq(asyncMachineRedeemer.nextRequestId(), ++_nextRequestId);

        assertEq(asyncMachineRedeemer.getShares(requestId1), shares1);
        assertEq(asyncMachineRedeemer.getShares(requestId2), shares2);
        assertEq(asyncMachineRedeemer.lastFinalizedRequestId(), 0);

        assertEq(machineShare.balanceOf(user1), 0);
        assertEq(machineShare.balanceOf(address(asyncMachineRedeemer)), shares1 + shares2);
        assertEq(accountingToken.balanceOf(user1), 0);

        assertEq(machineShare.balanceOf(user2), 0);
        assertEq(accountingToken.balanceOf(user2), 0);
    }
}
