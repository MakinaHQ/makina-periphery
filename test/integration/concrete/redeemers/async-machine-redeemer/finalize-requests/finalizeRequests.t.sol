// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

import {Errors, CoreErrors} from "src/libraries/Errors.sol";
import {IAsyncRedeemer} from "src/interfaces/IAsyncRedeemer.sol";

import {AsyncRedeemer_Integration_Concrete_Test} from "../AsyncRedeemer.t.sol";

contract FinalizeRequests_Integration_Concrete_Test is AsyncRedeemer_Integration_Concrete_Test {
    function setUp() public virtual override(AsyncRedeemer_Integration_Concrete_Test) {
        AsyncRedeemer_Integration_Concrete_Test.setUp();

        vm.prank(dao);
        hubPeripheryFactory.setMachine(address(asyncRedeemer), address(machine));
    }

    function test_RevertWhen_CallerNotMechanic() public {
        vm.expectRevert(CoreErrors.UnauthorizedCaller.selector);
        asyncRedeemer.finalizeRequests(0, 0);
    }

    function test_RevertWhen_NonExistentRequest() public {
        uint256 requestId = 1;
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, requestId));
        vm.prank(mechanic);
        asyncRedeemer.finalizeRequests(requestId, 0);
    }

    function test_RevertWhen_FinalizationDelayPending() public {
        uint256 assets = 1e18;

        // Deposit assets to the machine
        deal(address(accountingToken), depositorAddr, assets);
        vm.startPrank(depositorAddr);
        IERC20(accountingToken).approve(address(machine), assets);
        uint256 shares = machine.deposit(assets, user1, 0);
        vm.stopPrank();

        // User1 enters queue
        vm.startPrank(user1);
        machineShare.approve(address(asyncRedeemer), shares);
        uint256 requestId = asyncRedeemer.requestRedeem(shares, user3);
        vm.stopPrank();

        // Revert if trying to finalize before finalization delay
        vm.expectRevert(Errors.FinalizationDelayPending.selector);
        vm.prank(mechanic);
        asyncRedeemer.finalizeRequests(requestId, 0);
    }

    function test_RevertWhen_RequestAlreadyFinalized() public {
        uint256 assets = 1e18;

        // Deposit assets to the machine
        deal(address(accountingToken), depositorAddr, assets);
        vm.startPrank(depositorAddr);
        IERC20(accountingToken).approve(address(machine), assets);
        uint256 shares = machine.deposit(assets, user1, 0);
        vm.stopPrank();

        // User1 enters queue
        vm.startPrank(user1);
        machineShare.approve(address(asyncRedeemer), shares);
        uint256 requestId = asyncRedeemer.requestRedeem(shares, user3);
        vm.stopPrank();

        skip(asyncRedeemer.finalizationDelay());

        // Finalize requests
        vm.prank(mechanic);
        asyncRedeemer.finalizeRequests(requestId, 0);

        // Revert if trying to finalize again
        vm.expectRevert(Errors.AlreadyFinalized.selector);
        vm.prank(mechanic);
        asyncRedeemer.finalizeRequests(requestId, 0);
    }

    function test_FinalizeRequests_OneUser_OneSimultaneousSlot() public {
        uint256 inputAssets1 = 3e18;

        // Deposit assets to the machine
        deal(address(accountingToken), depositorAddr, inputAssets1);
        vm.startPrank(depositorAddr);
        IERC20(accountingToken).approve(address(machine), inputAssets1);
        uint256 mintedShares1 = machine.deposit(inputAssets1, user1, 0);
        vm.stopPrank();

        // User1 enters queue
        uint256 sharesToRedeem1 = mintedShares1 / 3; // User1 redeems half of their shares
        uint256 assetsToWithdraw1 = machine.convertToAssets(sharesToRedeem1);
        vm.startPrank(user1);
        machineShare.approve(address(asyncRedeemer), sharesToRedeem1);
        uint256 requestId1 = asyncRedeemer.requestRedeem(sharesToRedeem1, user3);
        vm.stopPrank();

        skip(asyncRedeemer.finalizationDelay());

        // Generate some positive yield in machine
        deal(address(accountingToken), address(machine), accountingToken.balanceOf(address(machine)) + 1e17);
        machine.updateTotalAum();

        (uint256 previewTotalShares, uint256 previewTotalAssets) = asyncRedeemer.previewFinalizeRequests(requestId1);

        // Finalize 1st request
        vm.prank(mechanic);
        vm.expectEmit(true, true, true, true, address(asyncRedeemer));
        emit IAsyncRedeemer.RedeemRequestsFinalized(requestId1, requestId1, sharesToRedeem1, assetsToWithdraw1);
        (uint256 totalShares, uint256 totalAssets) = asyncRedeemer.finalizeRequests(requestId1, assetsToWithdraw1);

        assertEq(previewTotalShares, totalShares);
        assertEq(previewTotalAssets, totalAssets);
        assertEq(asyncRedeemer.getShares(requestId1), sharesToRedeem1);
        assertEq(asyncRedeemer.getClaimableAssets(requestId1), assetsToWithdraw1);
        assertEq(asyncRedeemer.lastFinalizedRequestId(), requestId1);
        assertEq(machineShare.balanceOf(address(asyncRedeemer)), 0);
        assertEq(machineShare.balanceOf(user1), mintedShares1 - sharesToRedeem1);
        assertEq(machineShare.balanceOf(user3), 0);
        assertEq(accountingToken.balanceOf(address(asyncRedeemer)), assetsToWithdraw1);
        assertEq(accountingToken.balanceOf(user1), 0);
        assertEq(accountingToken.balanceOf(user3), 0);

        // User1 enters queue again
        uint256 sharesToRedeem2 = mintedShares1 - sharesToRedeem1; // User1 redeems rest of their shares
        vm.startPrank(user1);
        machineShare.approve(address(asyncRedeemer), sharesToRedeem2);
        uint256 requestId2 = asyncRedeemer.requestRedeem(sharesToRedeem2, user3);
        vm.stopPrank();

        skip(asyncRedeemer.finalizationDelay());

        assertEq(machineShare.balanceOf(address(asyncRedeemer)), sharesToRedeem2);

        // Generate some negative yield in machine
        deal(address(accountingToken), address(machine), accountingToken.balanceOf(address(machine)) - 1e18);
        machine.updateTotalAum();

        uint256 assetsToWithdraw2 = machine.convertToAssets(sharesToRedeem2);

        (previewTotalShares, previewTotalAssets) = asyncRedeemer.previewFinalizeRequests(requestId2);

        // Finalize 2nd request
        vm.prank(mechanic);
        vm.expectEmit(true, true, false, true, address(asyncRedeemer));
        emit IAsyncRedeemer.RedeemRequestsFinalized(requestId2, requestId2, sharesToRedeem2, assetsToWithdraw2);
        (totalShares, totalAssets) = asyncRedeemer.finalizeRequests(requestId2, assetsToWithdraw2);

        assertEq(previewTotalShares, totalShares);
        assertEq(previewTotalAssets, totalAssets);
        assertEq(asyncRedeemer.getShares(requestId1), sharesToRedeem1);
        assertEq(asyncRedeemer.getClaimableAssets(requestId1), assetsToWithdraw1);
        assertEq(asyncRedeemer.getShares(requestId2), sharesToRedeem2);
        assertEq(asyncRedeemer.getClaimableAssets(requestId2), assetsToWithdraw2);
        assertEq(asyncRedeemer.lastFinalizedRequestId(), requestId2);
        assertEq(machineShare.balanceOf(address(asyncRedeemer)), 0);
        assertEq(machineShare.balanceOf(user1), 0);
        assertEq(machineShare.balanceOf(user3), 0);
        assertEq(accountingToken.balanceOf(address(asyncRedeemer)), assetsToWithdraw1 + assetsToWithdraw2);
        assertEq(accountingToken.balanceOf(user1), 0);
        assertEq(accountingToken.balanceOf(user3), 0);
    }

    function test_FinalizeRequests_OneUser_TwoSimultaneousSlots() public {
        uint256 inputAssets1 = 3e18;

        // Deposit assets to the machine
        deal(address(accountingToken), depositorAddr, inputAssets1);
        vm.startPrank(depositorAddr);
        IERC20(accountingToken).approve(address(machine), inputAssets1);
        uint256 mintedShares1 = machine.deposit(inputAssets1, user1, 0);
        vm.stopPrank();

        // User1 enters queue
        uint256 sharesToRedeem1 = mintedShares1 / 3; // User1 redeems half of their shares
        uint256 assetsToWithdraw1 = machine.convertToAssets(sharesToRedeem1);
        vm.startPrank(user1);
        machineShare.approve(address(asyncRedeemer), sharesToRedeem1);
        uint256 requestId1 = asyncRedeemer.requestRedeem(sharesToRedeem1, user3);
        vm.stopPrank();

        // Generate some positive yield in machine
        deal(address(accountingToken), address(machine), accountingToken.balanceOf(address(machine)) + 1e17);
        machine.updateTotalAum();

        // User1 enters queue again
        uint256 sharesToRedeem2 = mintedShares1 - sharesToRedeem1; // User1 redeems rest of their shares
        vm.startPrank(user1);
        machineShare.approve(address(asyncRedeemer), sharesToRedeem2);
        uint256 requestId2 = asyncRedeemer.requestRedeem(sharesToRedeem2, user3);
        vm.stopPrank();

        skip(asyncRedeemer.finalizationDelay());

        (uint256 previewTotalShares, uint256 previewTotalAssets) = asyncRedeemer.previewFinalizeRequests(requestId1);

        // Finalize 1st request
        vm.prank(mechanic);
        vm.expectEmit(true, true, true, true, address(asyncRedeemer));
        emit IAsyncRedeemer.RedeemRequestsFinalized(requestId1, requestId1, sharesToRedeem1, assetsToWithdraw1);
        (uint256 totalShares, uint256 totalAssets) = asyncRedeemer.finalizeRequests(requestId1, assetsToWithdraw1);

        assertEq(previewTotalShares, totalShares);
        assertEq(previewTotalAssets, totalAssets);
        assertEq(asyncRedeemer.getShares(requestId1), sharesToRedeem1);
        assertEq(asyncRedeemer.getClaimableAssets(requestId1), assetsToWithdraw1);
        assertEq(asyncRedeemer.lastFinalizedRequestId(), requestId1);
        assertEq(machineShare.balanceOf(address(asyncRedeemer)), sharesToRedeem2);
        assertEq(machineShare.balanceOf(user1), 0);
        assertEq(machineShare.balanceOf(user3), 0);
        assertEq(accountingToken.balanceOf(address(asyncRedeemer)), assetsToWithdraw1);
        assertEq(accountingToken.balanceOf(user1), 0);
        assertEq(accountingToken.balanceOf(user3), 0);

        // Generate some negative yield in machine
        deal(address(accountingToken), address(machine), accountingToken.balanceOf(address(machine)) - 1e18);
        machine.updateTotalAum();

        uint256 assetsToWithdraw2 = machine.convertToAssets(sharesToRedeem2);

        (previewTotalShares, previewTotalAssets) = asyncRedeemer.previewFinalizeRequests(requestId2);

        // Finalize 2nd request
        vm.prank(mechanic);
        vm.expectEmit(true, true, false, true, address(asyncRedeemer));
        emit IAsyncRedeemer.RedeemRequestsFinalized(requestId2, requestId2, sharesToRedeem2, assetsToWithdraw2);
        (totalShares, totalAssets) = asyncRedeemer.finalizeRequests(requestId2, assetsToWithdraw2);

        assertEq(previewTotalShares, totalShares);
        assertEq(previewTotalAssets, totalAssets);
        assertEq(asyncRedeemer.getShares(requestId1), sharesToRedeem1);
        assertEq(asyncRedeemer.getClaimableAssets(requestId1), assetsToWithdraw1);
        assertEq(asyncRedeemer.getShares(requestId2), sharesToRedeem2);
        assertEq(asyncRedeemer.getClaimableAssets(requestId2), assetsToWithdraw2);
        assertEq(asyncRedeemer.lastFinalizedRequestId(), requestId2);
        assertEq(machineShare.balanceOf(address(asyncRedeemer)), 0);
        assertEq(machineShare.balanceOf(user1), 0);
        assertEq(machineShare.balanceOf(user3), 0);
        assertEq(accountingToken.balanceOf(address(asyncRedeemer)), assetsToWithdraw1 + assetsToWithdraw2);
        assertEq(accountingToken.balanceOf(user1), 0);
        assertEq(accountingToken.balanceOf(user3), 0);
    }

    function test_FinalizeRequests_TwoUsers() public {
        // Deposit assets to the machine
        deal(address(accountingToken), depositorAddr, 1e18 + 2e18);
        vm.startPrank(depositorAddr);
        IERC20(accountingToken).approve(address(machine), 1e18 + 2e18);
        uint256 mintedShares1 = machine.deposit(1e18, user1, 0);
        uint256 mintedShares2 = machine.deposit(2e18, user2, 0);
        vm.stopPrank();

        // User1 enters queue
        uint256 sharesToRedeem1 = mintedShares1 / 3; // User1 redeems half of their shares
        uint256 assetsToWithdraw1 = machine.convertToAssets(sharesToRedeem1);
        vm.startPrank(user1);
        machineShare.approve(address(asyncRedeemer), sharesToRedeem1);
        uint256 requestId1 = asyncRedeemer.requestRedeem(sharesToRedeem1, user3);
        vm.stopPrank();

        // Generate some positive yield in machine
        deal(address(accountingToken), address(machine), accountingToken.balanceOf(address(machine)) + 1e17);
        machine.updateTotalAum();

        // User2 enters queue
        uint256 sharesToRedeem2 = mintedShares2; // User2 redeems all of their shares
        vm.startPrank(user2);
        machineShare.approve(address(asyncRedeemer), sharesToRedeem2);
        uint256 requestId2 = asyncRedeemer.requestRedeem(sharesToRedeem2, user4);
        vm.stopPrank();

        skip(asyncRedeemer.finalizationDelay());

        (uint256 previewTotalShares, uint256 previewTotalAssets) = asyncRedeemer.previewFinalizeRequests(requestId1);

        // Finalize 1st request
        vm.prank(mechanic);
        vm.expectEmit(true, true, true, true, address(asyncRedeemer));
        emit IAsyncRedeemer.RedeemRequestsFinalized(requestId1, requestId1, sharesToRedeem1, assetsToWithdraw1);
        (uint256 totalShares, uint256 totalAssets) = asyncRedeemer.finalizeRequests(requestId1, assetsToWithdraw1);

        assertEq(previewTotalShares, totalShares);
        assertEq(previewTotalAssets, totalAssets);
        assertEq(asyncRedeemer.getShares(requestId1), sharesToRedeem1);
        assertEq(asyncRedeemer.getClaimableAssets(requestId1), assetsToWithdraw1);
        assertEq(asyncRedeemer.lastFinalizedRequestId(), requestId1);
        assertEq(machineShare.balanceOf(address(asyncRedeemer)), sharesToRedeem2);
        assertEq(machineShare.balanceOf(user1), mintedShares1 - sharesToRedeem1);
        assertEq(machineShare.balanceOf(user3), 0);
        assertEq(machineShare.balanceOf(user2), mintedShares2 - sharesToRedeem2);
        assertEq(accountingToken.balanceOf(address(asyncRedeemer)), assetsToWithdraw1);
        assertEq(accountingToken.balanceOf(user1), 0);
        assertEq(accountingToken.balanceOf(user3), 0);

        // User1 enters queue again
        uint256 sharesToRedeem3 = mintedShares1 - sharesToRedeem1; // User1 redeems rest of their shares
        vm.startPrank(user1);
        machineShare.approve(address(asyncRedeemer), sharesToRedeem3);
        uint256 requestId3 = asyncRedeemer.requestRedeem(sharesToRedeem3, user3);
        vm.stopPrank();

        skip(asyncRedeemer.finalizationDelay());

        assertEq(machineShare.balanceOf(address(asyncRedeemer)), sharesToRedeem2 + sharesToRedeem3);

        // Generate some negative yield in machine
        deal(address(accountingToken), address(machine), accountingToken.balanceOf(address(machine)) - 1e18);
        machine.updateTotalAum();

        uint256 assetsToWithdraw2 = machine.convertToAssets(sharesToRedeem2);
        uint256 assetsToWithdraw3 = machine.convertToAssets(sharesToRedeem3);

        (previewTotalShares, previewTotalAssets) = asyncRedeemer.previewFinalizeRequests(requestId3);

        // Finalize 2nd and 3rd requests
        vm.prank(mechanic);
        vm.expectEmit(true, true, false, true, address(asyncRedeemer));
        emit IAsyncRedeemer.RedeemRequestsFinalized(
            requestId2, requestId3, sharesToRedeem2 + sharesToRedeem3, assetsToWithdraw2 + assetsToWithdraw3
        );
        (totalShares, totalAssets) = asyncRedeemer.finalizeRequests(requestId3, assetsToWithdraw2 + assetsToWithdraw3);

        assertEq(previewTotalShares, totalShares);
        assertEq(previewTotalAssets, totalAssets);
        assertEq(asyncRedeemer.getShares(requestId1), sharesToRedeem1);
        assertEq(asyncRedeemer.getClaimableAssets(requestId1), assetsToWithdraw1);
        assertEq(asyncRedeemer.getShares(requestId2), sharesToRedeem2);
        assertEq(asyncRedeemer.getClaimableAssets(requestId2), assetsToWithdraw2);
        assertEq(asyncRedeemer.getShares(requestId3), sharesToRedeem3);
        assertEq(asyncRedeemer.getClaimableAssets(requestId3), assetsToWithdraw3);
        assertEq(asyncRedeemer.lastFinalizedRequestId(), requestId3);
        assertEq(machineShare.balanceOf(address(asyncRedeemer)), 0);
        assertEq(machineShare.balanceOf(user1), 0);
        assertEq(machineShare.balanceOf(user3), 0);
        assertEq(machineShare.balanceOf(user2), 0);
        assertEq(machineShare.balanceOf(user4), 0);
        assertEq(
            accountingToken.balanceOf(address(asyncRedeemer)), assetsToWithdraw1 + assetsToWithdraw2 + assetsToWithdraw3
        );
        assertEq(accountingToken.balanceOf(user1), 0);
        assertEq(accountingToken.balanceOf(user3), 0);
        assertEq(accountingToken.balanceOf(user2), 0);
        assertEq(accountingToken.balanceOf(user4), 0);
    }
}
