// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {CoreErrors} from "src/libraries/Errors.sol";
import {IAsyncMachineRedeemer} from "src/interfaces/IAsyncMachineRedeemer.sol";

import {WhitelistAsyncMachineRedeemer_Integration_Concrete_Test} from "../WhitelistAsyncMachineRedeemer.t.sol";

contract RequestRedeem_Integration_Concrete_Test is WhitelistAsyncMachineRedeemer_Integration_Concrete_Test {
    function test_RevertWhenUserNotWhitelisted() public {
        vm.expectRevert(CoreErrors.UnauthorizedCaller.selector);
        whitelistAsyncMachineRedeemer.requestRedeem(0, address(0));
    }

    function test_RequestRedeem()
        public
        withMachine(address(machine))
        withWhitelistedUser(user1)
        withWhitelistedUser(user2)
    {
        uint256 assets1 = 1e18;
        uint256 assets2 = 2e18;

        uint256 _nextRequestId = whitelistAsyncMachineRedeemer.nextRequestId();

        // Deposit assets to the machine
        deal(address(accountingToken), machineDepositorAddr, assets1 + assets2);
        vm.startPrank(machineDepositorAddr);
        IERC20(accountingToken).approve(address(machine), assets1 + assets2);
        uint256 shares1 = machine.deposit(assets1, user1, 0);
        uint256 shares2 = machine.deposit(assets2, user2, 0);
        vm.stopPrank();

        // User1 enters queue
        vm.startPrank(user1);
        machineShare.approve(address(whitelistAsyncMachineRedeemer), shares1);
        vm.expectEmit(true, true, true, true, address(whitelistAsyncMachineRedeemer));
        emit IAsyncMachineRedeemer.RedeemRequestCreated(_nextRequestId, shares1, user3);
        uint256 requestId1 = whitelistAsyncMachineRedeemer.requestRedeem(shares1, user3);
        vm.stopPrank();

        assertEq(requestId1, _nextRequestId);
        assertEq(whitelistAsyncMachineRedeemer.nextRequestId(), ++_nextRequestId);

        // User2 enters queue
        vm.startPrank(user2);
        machineShare.approve(address(whitelistAsyncMachineRedeemer), shares2);
        vm.expectEmit(true, true, true, true, address(whitelistAsyncMachineRedeemer));
        emit IAsyncMachineRedeemer.RedeemRequestCreated(_nextRequestId, shares2, user4);
        uint256 requestId2 = whitelistAsyncMachineRedeemer.requestRedeem(shares2, user4);
        vm.stopPrank();

        assertEq(requestId2, _nextRequestId);
        assertEq(whitelistAsyncMachineRedeemer.nextRequestId(), ++_nextRequestId);

        assertEq(whitelistAsyncMachineRedeemer.getShares(requestId1), shares1);
        assertEq(whitelistAsyncMachineRedeemer.getShares(requestId2), shares2);
        assertEq(whitelistAsyncMachineRedeemer.lastFinalizedRequestId(), 0);
    }
}
