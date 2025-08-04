// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

import {Errors, CoreErrors} from "src/libraries/Errors.sol";
import {IAsyncMachineRedeemer} from "src/interfaces/IAsyncMachineRedeemer.sol";
import {IMachinePeriphery} from "src/interfaces/IMachinePeriphery.sol";

import {AsyncMachineRedeemer_Integration_Concrete_Test} from "../AsyncMachineRedeemer.t.sol";

contract FinalizeRequests_Integration_Concrete_Test is AsyncMachineRedeemer_Integration_Concrete_Test {
    function setUp() public virtual override(AsyncMachineRedeemer_Integration_Concrete_Test) {
        AsyncMachineRedeemer_Integration_Concrete_Test.setUp();

        vm.prank(address(hubPeripheryFactory));
        asyncMachineRedeemer.setMachine(address(machine));
    }

    function test_RevertWhen_CallerNotMechanic() public {
        vm.expectRevert(CoreErrors.UnauthorizedCaller.selector);
        asyncMachineRedeemer.finalizeRequests(0, 0);
    }

    function test_RevertWhen_NonExistentRequest() public {
        uint256 requestId = 1;
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, requestId));
        vm.prank(mechanic);
        asyncMachineRedeemer.finalizeRequests(requestId, 0);
    }

    function test_RevertWhen_FinalizationDelayPending() public {
        uint256 assets = 1e18;

        // Deposit assets to the machine
        deal(address(accountingToken), machineDepositorAddr, assets);
        vm.startPrank(machineDepositorAddr);
        IERC20(accountingToken).approve(address(machine), assets);
        uint256 shares = machine.deposit(assets, user1, 0);
        vm.stopPrank();

        // User1 enters queue
        vm.startPrank(user1);
        machineShare.approve(address(asyncMachineRedeemer), shares);
        uint256 requestId = asyncMachineRedeemer.requestRedeem(shares, user3);
        vm.stopPrank();

        // Revert if trying to finalize before finalization delay
        vm.expectRevert(Errors.FinalizationDelayPending.selector);
        vm.prank(mechanic);
        asyncMachineRedeemer.finalizeRequests(requestId, 0);
    }

    function test_RevertWhen_RequestAlreadyFinalized() public {
        uint256 assets = 1e18;

        // Deposit assets to the machine
        deal(address(accountingToken), machineDepositorAddr, assets);
        vm.startPrank(machineDepositorAddr);
        IERC20(accountingToken).approve(address(machine), assets);
        uint256 shares = machine.deposit(assets, user1, 0);
        vm.stopPrank();

        // User1 enters queue
        vm.startPrank(user1);
        machineShare.approve(address(asyncMachineRedeemer), shares);
        uint256 requestId = asyncMachineRedeemer.requestRedeem(shares, user3);
        vm.stopPrank();

        skip(asyncMachineRedeemer.finalizationDelay());

        // Finalize requests
        vm.prank(mechanic);
        asyncMachineRedeemer.finalizeRequests(requestId, 0);

        // Revert if trying to finalize again
        vm.expectRevert(Errors.AlreadyFinalized.selector);
        vm.prank(mechanic);
        asyncMachineRedeemer.finalizeRequests(requestId, 0);
    }

    function test_FinalizeRequests_OneUser_OneSimultaneousSlot() public {
        uint256 inputAssets1 = 3e18;

        // Deposit assets to the machine
        deal(address(accountingToken), machineDepositorAddr, inputAssets1);
        vm.startPrank(machineDepositorAddr);
        IERC20(accountingToken).approve(address(machine), inputAssets1);
        uint256 mintedShares1 = machine.deposit(inputAssets1, user1, 0);
        vm.stopPrank();

        // User1 enters queue
        uint256 sharesToRedeem1 = mintedShares1 / 3; // User1 redeems half of their shares
        uint256 assetsToWithdraw1 = machine.convertToAssets(sharesToRedeem1);
        vm.startPrank(user1);
        machineShare.approve(address(asyncMachineRedeemer), sharesToRedeem1);
        uint256 requestId1 = asyncMachineRedeemer.requestRedeem(sharesToRedeem1, user3);
        vm.stopPrank();

        skip(asyncMachineRedeemer.finalizationDelay());

        // Generate some positive yield in machine
        deal(address(accountingToken), address(machine), accountingToken.balanceOf(address(machine)) + 1e17);
        machine.updateTotalAum();

        (uint256 previewTotalShares, uint256 previewTotalAssets) =
            asyncMachineRedeemer.previewFinalizeRequests(requestId1);

        // Finalize 1st request
        vm.prank(mechanic);
        vm.expectEmit(true, true, true, true, address(asyncMachineRedeemer));
        emit IAsyncMachineRedeemer.RedeemRequestsFinalized(requestId1, requestId1, sharesToRedeem1, assetsToWithdraw1);
        (uint256 totalShares, uint256 totalAssets) =
            asyncMachineRedeemer.finalizeRequests(requestId1, assetsToWithdraw1);

        assertEq(previewTotalShares, totalShares);
        assertEq(previewTotalAssets, totalAssets);
        assertEq(asyncMachineRedeemer.getShares(requestId1), sharesToRedeem1);
        assertEq(asyncMachineRedeemer.getClaimableAssets(requestId1), assetsToWithdraw1);
        assertEq(asyncMachineRedeemer.lastFinalizedRequestId(), requestId1);
        assertEq(machineShare.balanceOf(address(asyncMachineRedeemer)), 0);
        assertEq(machineShare.balanceOf(user1), mintedShares1 - sharesToRedeem1);
        assertEq(machineShare.balanceOf(user3), 0);
        assertEq(accountingToken.balanceOf(address(asyncMachineRedeemer)), assetsToWithdraw1);
        assertEq(accountingToken.balanceOf(user1), 0);
        assertEq(accountingToken.balanceOf(user3), 0);

        // User1 enters queue again
        uint256 sharesToRedeem2 = mintedShares1 - sharesToRedeem1; // User1 redeems rest of their shares
        vm.startPrank(user1);
        machineShare.approve(address(asyncMachineRedeemer), sharesToRedeem2);
        uint256 requestId2 = asyncMachineRedeemer.requestRedeem(sharesToRedeem2, user3);
        vm.stopPrank();

        skip(asyncMachineRedeemer.finalizationDelay());

        assertEq(machineShare.balanceOf(address(asyncMachineRedeemer)), sharesToRedeem2);

        // Generate some negative yield in machine
        deal(address(accountingToken), address(machine), accountingToken.balanceOf(address(machine)) - 1e18);
        machine.updateTotalAum();

        uint256 assetsToWithdraw2 = machine.convertToAssets(sharesToRedeem2);

        (previewTotalShares, previewTotalAssets) = asyncMachineRedeemer.previewFinalizeRequests(requestId2);

        // Finalize 2nd request
        vm.prank(mechanic);
        vm.expectEmit(true, true, false, true, address(asyncMachineRedeemer));
        emit IAsyncMachineRedeemer.RedeemRequestsFinalized(requestId2, requestId2, sharesToRedeem2, assetsToWithdraw2);
        (totalShares, totalAssets) = asyncMachineRedeemer.finalizeRequests(requestId2, assetsToWithdraw2);

        assertEq(previewTotalShares, totalShares);
        assertEq(previewTotalAssets, totalAssets);
        assertEq(asyncMachineRedeemer.getShares(requestId1), sharesToRedeem1);
        assertEq(asyncMachineRedeemer.getClaimableAssets(requestId1), assetsToWithdraw1);
        assertEq(asyncMachineRedeemer.getShares(requestId2), sharesToRedeem2);
        assertEq(asyncMachineRedeemer.getClaimableAssets(requestId2), assetsToWithdraw2);
        assertEq(asyncMachineRedeemer.lastFinalizedRequestId(), requestId2);
        assertEq(machineShare.balanceOf(address(asyncMachineRedeemer)), 0);
        assertEq(machineShare.balanceOf(user1), 0);
        assertEq(machineShare.balanceOf(user3), 0);
        assertEq(accountingToken.balanceOf(address(asyncMachineRedeemer)), assetsToWithdraw1 + assetsToWithdraw2);
        assertEq(accountingToken.balanceOf(user1), 0);
        assertEq(accountingToken.balanceOf(user3), 0);
    }

    function test_FinalizeRequests_OneUser_TwoSimultaneousSlots() public {
        uint256 inputAssets1 = 3e18;

        // Deposit assets to the machine
        deal(address(accountingToken), machineDepositorAddr, inputAssets1);
        vm.startPrank(machineDepositorAddr);
        IERC20(accountingToken).approve(address(machine), inputAssets1);
        uint256 mintedShares1 = machine.deposit(inputAssets1, user1, 0);
        vm.stopPrank();

        // User1 enters queue
        uint256 sharesToRedeem1 = mintedShares1 / 3; // User1 redeems half of their shares
        uint256 assetsToWithdraw1 = machine.convertToAssets(sharesToRedeem1);
        vm.startPrank(user1);
        machineShare.approve(address(asyncMachineRedeemer), sharesToRedeem1);
        uint256 requestId1 = asyncMachineRedeemer.requestRedeem(sharesToRedeem1, user3);
        vm.stopPrank();

        // Generate some positive yield in machine
        deal(address(accountingToken), address(machine), accountingToken.balanceOf(address(machine)) + 1e17);
        machine.updateTotalAum();

        // User1 enters queue again
        uint256 sharesToRedeem2 = mintedShares1 - sharesToRedeem1; // User1 redeems rest of their shares
        vm.startPrank(user1);
        machineShare.approve(address(asyncMachineRedeemer), sharesToRedeem2);
        uint256 requestId2 = asyncMachineRedeemer.requestRedeem(sharesToRedeem2, user3);
        vm.stopPrank();

        skip(asyncMachineRedeemer.finalizationDelay());

        (uint256 previewTotalShares, uint256 previewTotalAssets) =
            asyncMachineRedeemer.previewFinalizeRequests(requestId1);

        // Finalize 1st request
        vm.prank(mechanic);
        vm.expectEmit(true, true, true, true, address(asyncMachineRedeemer));
        emit IAsyncMachineRedeemer.RedeemRequestsFinalized(requestId1, requestId1, sharesToRedeem1, assetsToWithdraw1);
        (uint256 totalShares, uint256 totalAssets) =
            asyncMachineRedeemer.finalizeRequests(requestId1, assetsToWithdraw1);

        assertEq(previewTotalShares, totalShares);
        assertEq(previewTotalAssets, totalAssets);
        assertEq(asyncMachineRedeemer.getShares(requestId1), sharesToRedeem1);
        assertEq(asyncMachineRedeemer.getClaimableAssets(requestId1), assetsToWithdraw1);
        assertEq(asyncMachineRedeemer.lastFinalizedRequestId(), requestId1);
        assertEq(machineShare.balanceOf(address(asyncMachineRedeemer)), sharesToRedeem2);
        assertEq(machineShare.balanceOf(user1), 0);
        assertEq(machineShare.balanceOf(user3), 0);
        assertEq(accountingToken.balanceOf(address(asyncMachineRedeemer)), assetsToWithdraw1);
        assertEq(accountingToken.balanceOf(user1), 0);
        assertEq(accountingToken.balanceOf(user3), 0);

        // Generate some negative yield in machine
        deal(address(accountingToken), address(machine), accountingToken.balanceOf(address(machine)) - 1e18);
        machine.updateTotalAum();

        uint256 assetsToWithdraw2 = machine.convertToAssets(sharesToRedeem2);

        (previewTotalShares, previewTotalAssets) = asyncMachineRedeemer.previewFinalizeRequests(requestId2);

        // Finalize 2nd request
        vm.prank(mechanic);
        vm.expectEmit(true, true, false, true, address(asyncMachineRedeemer));
        emit IAsyncMachineRedeemer.RedeemRequestsFinalized(requestId2, requestId2, sharesToRedeem2, assetsToWithdraw2);
        (totalShares, totalAssets) = asyncMachineRedeemer.finalizeRequests(requestId2, assetsToWithdraw2);

        assertEq(previewTotalShares, totalShares);
        assertEq(previewTotalAssets, totalAssets);
        assertEq(asyncMachineRedeemer.getShares(requestId1), sharesToRedeem1);
        assertEq(asyncMachineRedeemer.getClaimableAssets(requestId1), assetsToWithdraw1);
        assertEq(asyncMachineRedeemer.getShares(requestId2), sharesToRedeem2);
        assertEq(asyncMachineRedeemer.getClaimableAssets(requestId2), assetsToWithdraw2);
        assertEq(asyncMachineRedeemer.lastFinalizedRequestId(), requestId2);
        assertEq(machineShare.balanceOf(address(asyncMachineRedeemer)), 0);
        assertEq(machineShare.balanceOf(user1), 0);
        assertEq(machineShare.balanceOf(user3), 0);
        assertEq(accountingToken.balanceOf(address(asyncMachineRedeemer)), assetsToWithdraw1 + assetsToWithdraw2);
        assertEq(accountingToken.balanceOf(user1), 0);
        assertEq(accountingToken.balanceOf(user3), 0);
    }

    function test_FinalizeRequests_TwoUsers() public {
        // Deposit assets to the machine
        deal(address(accountingToken), machineDepositorAddr, 1e18 + 2e18);
        vm.startPrank(machineDepositorAddr);
        IERC20(accountingToken).approve(address(machine), 1e18 + 2e18);
        uint256 mintedShares1 = machine.deposit(1e18, user1, 0);
        uint256 mintedShares2 = machine.deposit(2e18, user2, 0);
        vm.stopPrank();

        // User1 enters queue
        uint256 sharesToRedeem1 = mintedShares1 / 3; // User1 redeems half of their shares
        uint256 assetsToWithdraw1 = machine.convertToAssets(sharesToRedeem1);
        vm.startPrank(user1);
        machineShare.approve(address(asyncMachineRedeemer), sharesToRedeem1);
        uint256 requestId1 = asyncMachineRedeemer.requestRedeem(sharesToRedeem1, user3);
        vm.stopPrank();

        // Generate some positive yield in machine
        deal(address(accountingToken), address(machine), accountingToken.balanceOf(address(machine)) + 1e17);
        machine.updateTotalAum();

        // User2 enters queue
        uint256 sharesToRedeem2 = mintedShares2; // User2 redeems all of their shares
        vm.startPrank(user2);
        machineShare.approve(address(asyncMachineRedeemer), sharesToRedeem2);
        uint256 requestId2 = asyncMachineRedeemer.requestRedeem(sharesToRedeem2, user4);
        vm.stopPrank();

        skip(asyncMachineRedeemer.finalizationDelay());

        (uint256 previewTotalShares, uint256 previewTotalAssets) =
            asyncMachineRedeemer.previewFinalizeRequests(requestId1);

        // Finalize 1st request
        vm.prank(mechanic);
        vm.expectEmit(true, true, true, true, address(asyncMachineRedeemer));
        emit IAsyncMachineRedeemer.RedeemRequestsFinalized(requestId1, requestId1, sharesToRedeem1, assetsToWithdraw1);
        (uint256 totalShares, uint256 totalAssets) =
            asyncMachineRedeemer.finalizeRequests(requestId1, assetsToWithdraw1);

        assertEq(previewTotalShares, totalShares);
        assertEq(previewTotalAssets, totalAssets);
        assertEq(asyncMachineRedeemer.getShares(requestId1), sharesToRedeem1);
        assertEq(asyncMachineRedeemer.getClaimableAssets(requestId1), assetsToWithdraw1);
        assertEq(asyncMachineRedeemer.lastFinalizedRequestId(), requestId1);
        assertEq(machineShare.balanceOf(address(asyncMachineRedeemer)), sharesToRedeem2);
        assertEq(machineShare.balanceOf(user1), mintedShares1 - sharesToRedeem1);
        assertEq(machineShare.balanceOf(user3), 0);
        assertEq(machineShare.balanceOf(user2), mintedShares2 - sharesToRedeem2);
        assertEq(accountingToken.balanceOf(address(asyncMachineRedeemer)), assetsToWithdraw1);
        assertEq(accountingToken.balanceOf(user1), 0);
        assertEq(accountingToken.balanceOf(user3), 0);

        // User1 enters queue again
        uint256 sharesToRedeem3 = mintedShares1 - sharesToRedeem1; // User1 redeems rest of their shares
        vm.startPrank(user1);
        machineShare.approve(address(asyncMachineRedeemer), sharesToRedeem3);
        uint256 requestId3 = asyncMachineRedeemer.requestRedeem(sharesToRedeem3, user3);
        vm.stopPrank();

        skip(asyncMachineRedeemer.finalizationDelay());

        assertEq(machineShare.balanceOf(address(asyncMachineRedeemer)), sharesToRedeem2 + sharesToRedeem3);

        // Generate some negative yield in machine
        deal(address(accountingToken), address(machine), accountingToken.balanceOf(address(machine)) - 1e18);
        machine.updateTotalAum();

        uint256 assetsToWithdraw2 = machine.convertToAssets(sharesToRedeem2);
        uint256 assetsToWithdraw3 = machine.convertToAssets(sharesToRedeem3);

        (previewTotalShares, previewTotalAssets) = asyncMachineRedeemer.previewFinalizeRequests(requestId3);

        // Finalize 2nd and 3rd requests
        vm.prank(mechanic);
        vm.expectEmit(true, true, false, true, address(asyncMachineRedeemer));
        emit IAsyncMachineRedeemer.RedeemRequestsFinalized(
            requestId2, requestId3, sharesToRedeem2 + sharesToRedeem3, assetsToWithdraw2 + assetsToWithdraw3
        );
        (totalShares, totalAssets) =
            asyncMachineRedeemer.finalizeRequests(requestId3, assetsToWithdraw2 + assetsToWithdraw3);

        assertEq(previewTotalShares, totalShares);
        assertEq(previewTotalAssets, totalAssets);
        assertEq(asyncMachineRedeemer.getShares(requestId1), sharesToRedeem1);
        assertEq(asyncMachineRedeemer.getClaimableAssets(requestId1), assetsToWithdraw1);
        assertEq(asyncMachineRedeemer.getShares(requestId2), sharesToRedeem2);
        assertEq(asyncMachineRedeemer.getClaimableAssets(requestId2), assetsToWithdraw2);
        assertEq(asyncMachineRedeemer.getShares(requestId3), sharesToRedeem3);
        assertEq(asyncMachineRedeemer.getClaimableAssets(requestId3), assetsToWithdraw3);
        assertEq(asyncMachineRedeemer.lastFinalizedRequestId(), requestId3);
        assertEq(machineShare.balanceOf(address(asyncMachineRedeemer)), 0);
        assertEq(machineShare.balanceOf(user1), 0);
        assertEq(machineShare.balanceOf(user3), 0);
        assertEq(machineShare.balanceOf(user2), 0);
        assertEq(machineShare.balanceOf(user4), 0);
        assertEq(
            accountingToken.balanceOf(address(asyncMachineRedeemer)),
            assetsToWithdraw1 + assetsToWithdraw2 + assetsToWithdraw3
        );
        assertEq(accountingToken.balanceOf(user1), 0);
        assertEq(accountingToken.balanceOf(user3), 0);
        assertEq(accountingToken.balanceOf(user2), 0);
        assertEq(accountingToken.balanceOf(user4), 0);
    }
}
