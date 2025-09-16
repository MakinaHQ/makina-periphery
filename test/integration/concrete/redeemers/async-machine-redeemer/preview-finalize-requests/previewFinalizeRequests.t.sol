// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

import {Errors} from "src/libraries/Errors.sol";

import {AsyncRedeemer_Integration_Concrete_Test} from "../AsyncRedeemer.t.sol";

contract PreviewFinalizeRequests_Integration_Concrete_Test is AsyncRedeemer_Integration_Concrete_Test {
    function setUp() public virtual override(AsyncRedeemer_Integration_Concrete_Test) {
        AsyncRedeemer_Integration_Concrete_Test.setUp();

        vm.prank(dao);
        hubPeripheryFactory.setMachine(address(asyncRedeemer), address(machine));
    }

    function test_RevertWhen_NonExistentRequest() public virtual {
        uint256 requestId = 1;
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, requestId));
        vm.prank(mechanic);
        asyncRedeemer.previewFinalizeRequests(requestId);
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

        // Revert if trying to preview finalize requests before finalization delay
        vm.expectRevert(Errors.FinalizationDelayPending.selector);
        asyncRedeemer.previewFinalizeRequests(requestId);
    }

    function test_RevertWhen_RequestAlreadyFinalized() public virtual {
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
        asyncRedeemer.previewFinalizeRequests(requestId);
    }

    function test_PreviewFinalizeRequests_OneUser_OneSimultaneousSlot() public virtual {
        uint256 inputAssets1 = 3e18;

        // Deposit assets to the machine
        deal(address(accountingToken), depositorAddr, inputAssets1);
        vm.startPrank(depositorAddr);
        IERC20(accountingToken).approve(address(machine), inputAssets1);
        uint256 mintedShares1 = machine.deposit(inputAssets1, user1, 0);
        vm.stopPrank();

        // User1 enters queue
        uint256 sharesToRedeem1 = mintedShares1 / 3; // User1 redeems part of their shares
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

        assertEq(previewTotalShares, sharesToRedeem1);
        assertEq(previewTotalAssets, assetsToWithdraw1);

        // Finalize 1st request
        vm.prank(mechanic);
        (uint256 totalShares, uint256 totalAssets) = asyncRedeemer.finalizeRequests(requestId1, assetsToWithdraw1);

        assertEq(previewTotalShares, totalShares);
        assertEq(previewTotalAssets, totalAssets);

        // User1 enters queue again
        uint256 sharesToRedeem2 = mintedShares1 - sharesToRedeem1; // User1 redeems rest of their shares
        vm.startPrank(user1);
        machineShare.approve(address(asyncRedeemer), sharesToRedeem2);
        uint256 requestId2 = asyncRedeemer.requestRedeem(sharesToRedeem2, user3);
        vm.stopPrank();

        skip(asyncRedeemer.finalizationDelay());

        // Generate some negative yield in machine
        deal(address(accountingToken), address(machine), accountingToken.balanceOf(address(machine)) - 1e18);
        machine.updateTotalAum();

        uint256 assetsToWithdraw2 = machine.convertToAssets(sharesToRedeem2);

        (previewTotalShares, previewTotalAssets) = asyncRedeemer.previewFinalizeRequests(requestId2);

        assertEq(previewTotalShares, sharesToRedeem2);
        assertEq(previewTotalAssets, assetsToWithdraw2);

        // Finalize 2nd request
        vm.prank(mechanic);
        (totalShares, totalAssets) = asyncRedeemer.finalizeRequests(requestId2, assetsToWithdraw2);

        assertEq(previewTotalShares, totalShares);
        assertEq(previewTotalAssets, totalAssets);
    }

    function test_PreviewFinalizeRequests_OneUser_TwoSimultaneousSlots() public virtual {
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
        uint256 assetsToWithdraw2 = machine.convertToAssets(sharesToRedeem2);
        vm.startPrank(user1);
        machineShare.approve(address(asyncRedeemer), sharesToRedeem2);
        uint256 requestId2 = asyncRedeemer.requestRedeem(sharesToRedeem2, user3);
        vm.stopPrank();

        skip(asyncRedeemer.finalizationDelay());

        (uint256 previewTotalShares, uint256 previewTotalAssets) = asyncRedeemer.previewFinalizeRequests(requestId2);

        assertEq(previewTotalShares, sharesToRedeem1 + sharesToRedeem2);
        assertEq(previewTotalAssets, assetsToWithdraw1 + assetsToWithdraw2);

        (previewTotalShares, previewTotalAssets) = asyncRedeemer.previewFinalizeRequests(requestId1);

        assertEq(previewTotalShares, sharesToRedeem1);
        assertEq(previewTotalAssets, assetsToWithdraw1);

        // Finalize 1st request
        vm.prank(mechanic);
        (uint256 totalShares, uint256 totalAssets) = asyncRedeemer.finalizeRequests(requestId1, assetsToWithdraw1);

        assertEq(previewTotalShares, totalShares);
        assertEq(previewTotalAssets, totalAssets);

        // Generate some negative yield in machine
        deal(address(accountingToken), address(machine), accountingToken.balanceOf(address(machine)) - 1e18);
        machine.updateTotalAum();

        assetsToWithdraw2 = machine.convertToAssets(sharesToRedeem2);

        (previewTotalShares, previewTotalAssets) = asyncRedeemer.previewFinalizeRequests(requestId2);

        assertEq(previewTotalAssets, assetsToWithdraw2);

        // Finalize 2nd request
        vm.prank(mechanic);
        (totalShares, totalAssets) = asyncRedeemer.finalizeRequests(requestId2, assetsToWithdraw2);

        assertEq(previewTotalShares, totalShares);
        assertEq(previewTotalAssets, totalAssets);
    }

    function test_PreviewFinalizeRequests_TwoUsers() public virtual {
        uint256 inputAssets1 = 1e18;
        uint256 inputAssets2 = 2e18;

        // Deposit assets to the machine
        deal(address(accountingToken), depositorAddr, inputAssets1 + inputAssets2);
        vm.startPrank(depositorAddr);
        IERC20(accountingToken).approve(address(machine), inputAssets1 + inputAssets2);
        uint256 mintedShares1 = machine.deposit(inputAssets1, user1, 0);
        uint256 mintedShares2 = machine.deposit(inputAssets2, user2, 0);
        vm.stopPrank();

        // User1 enters queue
        uint256 sharesToRedeem1 = mintedShares1 / 3; // User1 redeems part of their shares
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
        uint256 assetsToWithdraw2 = machine.convertToAssets(sharesToRedeem2);
        vm.startPrank(user2);
        machineShare.approve(address(asyncRedeemer), sharesToRedeem2);
        uint256 requestId2 = asyncRedeemer.requestRedeem(sharesToRedeem2, user4);
        vm.stopPrank();

        skip(asyncRedeemer.finalizationDelay());

        (uint256 previewTotalShares, uint256 previewTotalAssets) = asyncRedeemer.previewFinalizeRequests(requestId2);

        assertEq(previewTotalShares, sharesToRedeem1 + sharesToRedeem2);
        assertEq(previewTotalAssets, assetsToWithdraw1 + assetsToWithdraw2);

        (previewTotalShares, previewTotalAssets) = asyncRedeemer.previewFinalizeRequests(requestId1);

        assertEq(previewTotalShares, sharesToRedeem1);
        assertEq(previewTotalAssets, assetsToWithdraw1);

        // Finalize 1st request
        vm.prank(mechanic);
        (uint256 totalShares, uint256 totalAssets) = asyncRedeemer.finalizeRequests(requestId1, assetsToWithdraw1);

        assertEq(previewTotalShares, totalShares);
        assertEq(previewTotalAssets, totalAssets);

        // Generate some negative yield in machine
        deal(address(accountingToken), address(machine), accountingToken.balanceOf(address(machine)) - 1e18);
        machine.updateTotalAum();

        // User1 enters queue again
        sharesToRedeem1 = mintedShares1 - sharesToRedeem1; // User1 redeems rest of their shares
        assetsToWithdraw1 = machine.convertToAssets(sharesToRedeem1);
        vm.startPrank(user1);
        machineShare.approve(address(asyncRedeemer), sharesToRedeem1);
        uint256 requestId3 = asyncRedeemer.requestRedeem(sharesToRedeem1, user3);
        vm.stopPrank();

        skip(asyncRedeemer.finalizationDelay());

        (previewTotalShares, previewTotalAssets) = asyncRedeemer.previewFinalizeRequests(requestId2);
        assertEq(previewTotalShares, sharesToRedeem2);
        assertLt(previewTotalAssets, assetsToWithdraw2);

        assetsToWithdraw2 = machine.convertToAssets(sharesToRedeem2);

        (previewTotalShares, previewTotalAssets) = asyncRedeemer.previewFinalizeRequests(requestId3);
        assertEq(previewTotalShares, sharesToRedeem2 + sharesToRedeem1);
        assertEq(previewTotalAssets, assetsToWithdraw2 + assetsToWithdraw1);

        // Finalize 2nd and 3rd requests
        vm.prank(mechanic);
        (totalShares, totalAssets) = asyncRedeemer.finalizeRequests(requestId3, assetsToWithdraw2 + assetsToWithdraw1);

        assertEq(previewTotalShares, totalShares);
        assertEq(previewTotalAssets, totalAssets);
    }
}
