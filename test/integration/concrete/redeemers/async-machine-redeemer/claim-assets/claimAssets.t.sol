// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

import {Errors, CoreErrors} from "src/libraries/Errors.sol";
import {IAsyncRedeemer} from "src/interfaces/IAsyncRedeemer.sol";

import {AsyncRedeemer_Integration_Concrete_Test} from "../AsyncRedeemer.t.sol";

contract ClaimAssets_Integration_Concrete_Test is AsyncRedeemer_Integration_Concrete_Test {
    function setUp() public virtual override(AsyncRedeemer_Integration_Concrete_Test) {
        AsyncRedeemer_Integration_Concrete_Test.setUp();

        vm.prank(dao);
        hubPeripheryFactory.setMachine(address(asyncRedeemer), address(machine));
    }

    function test_RevertWhen_UnauthorizedCaller_WithWhitelistEnabled() public withWhitelistEnabled {
        vm.expectRevert(CoreErrors.UnauthorizedCaller.selector);
        asyncRedeemer.claimAssets(1);
    }

    function test_RevertWhen_NonExistentRequest() public {
        uint256 requestId = 1;
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, requestId));
        asyncRedeemer.claimAssets(requestId);
    }

    function test_RevertWhen_IncorrectOwner() public {
        uint256 assets = 1e18;

        // Deposit assets to the machine
        deal(address(accountingToken), depositorAddr, assets);
        vm.startPrank(depositorAddr);
        IERC20(accountingToken).approve(address(machine), assets);
        uint256 shares = machine.deposit(assets, user1, 0);
        vm.stopPrank();

        // User1 enters queue, User3 is the receiver
        vm.startPrank(user1);
        machineShare.approve(address(asyncRedeemer), shares);
        uint256 requestId = asyncRedeemer.requestRedeem(shares, user3);

        // User1 tries to claim assets
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721IncorrectOwner.selector, user1, requestId, user3));
        asyncRedeemer.claimAssets(requestId);
    }

    function test_RevertGiven_RequestNotFinalized() public {
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

        vm.expectRevert(Errors.NotFinalized.selector);
        vm.prank(user3);
        asyncRedeemer.claimAssets(requestId);
    }

    function test_ClaimAssets_OneUser_OneSimultaneousSlot() public {
        uint256 inputAssets1 = 3e18;

        // Deposit assets to the machine
        deal(address(accountingToken), depositorAddr, inputAssets1);
        vm.startPrank(depositorAddr);
        IERC20(accountingToken).approve(address(machine), inputAssets1);
        uint256 mintedShares1 = machine.deposit(inputAssets1, user1, 0);
        vm.stopPrank();

        // User1 enters queue
        uint256 sharesToRedeem1 = mintedShares1 / 3;
        uint256 assetsToWithdraw1 = machine.convertToAssets(sharesToRedeem1);
        vm.startPrank(user1);
        machineShare.approve(address(asyncRedeemer), sharesToRedeem1);
        uint256 requestId1 = asyncRedeemer.requestRedeem(sharesToRedeem1, user3);
        vm.stopPrank();

        skip(asyncRedeemer.finalizationDelay());

        // Generate some positive yield in machine
        deal(address(accountingToken), address(machine), accountingToken.balanceOf(address(machine)) + 1e17);
        machine.updateTotalAum();

        // Finalize 1st request
        vm.prank(mechanic);
        asyncRedeemer.finalizeRequests(requestId1, assetsToWithdraw1);

        // User3 claims assets
        vm.expectEmit(true, true, false, true, address(asyncRedeemer));
        emit IAsyncRedeemer.RedeemRequestClaimed(requestId1, sharesToRedeem1, assetsToWithdraw1, user3);
        vm.prank(user3);
        uint256 claimedAssets = asyncRedeemer.claimAssets(requestId1);

        assertEq(claimedAssets, assetsToWithdraw1);
        assertEq(accountingToken.balanceOf(user3), claimedAssets);

        // User1 enters queue again
        uint256 sharesToRedeem2 = mintedShares1 - sharesToRedeem1;
        vm.startPrank(user1);
        machineShare.approve(address(asyncRedeemer), sharesToRedeem2);
        uint256 requestId2 = asyncRedeemer.requestRedeem(sharesToRedeem2, user4);
        vm.stopPrank();

        skip(asyncRedeemer.finalizationDelay());

        // Generate some negative yield in machine
        deal(address(accountingToken), address(machine), accountingToken.balanceOf(address(machine)) - 1e18);
        machine.updateTotalAum();

        uint256 assetsToWithdraw2 = machine.convertToAssets(sharesToRedeem2);

        // Finalize 2nd request
        vm.prank(mechanic);
        asyncRedeemer.finalizeRequests(requestId2, assetsToWithdraw2);

        // User4 claims assets
        vm.expectEmit(true, true, false, false, address(asyncRedeemer));
        emit IAsyncRedeemer.RedeemRequestClaimed(requestId2, sharesToRedeem2, assetsToWithdraw2, user4);
        vm.prank(user4);
        claimedAssets = asyncRedeemer.claimAssets(requestId2);

        assertEq(claimedAssets, assetsToWithdraw2);
        assertEq(accountingToken.balanceOf(user4), claimedAssets);

        assertEq(accountingToken.balanceOf(address(asyncRedeemer)), 0);
    }

    function test_ClaimAssets_OneUser_TwoSimultaneousSlots() public {
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
        uint256 requestId2 = asyncRedeemer.requestRedeem(sharesToRedeem2, user4);
        vm.stopPrank();

        skip(asyncRedeemer.finalizationDelay());

        // Finalize 1st request
        vm.prank(mechanic);
        asyncRedeemer.finalizeRequests(requestId1, assetsToWithdraw1);

        // Generate some negative yield in machine
        deal(address(accountingToken), address(machine), accountingToken.balanceOf(address(machine)) - 1e18);
        machine.updateTotalAum();

        // User3 claims assets
        vm.expectEmit(true, true, false, true, address(asyncRedeemer));
        emit IAsyncRedeemer.RedeemRequestClaimed(requestId1, sharesToRedeem1, assetsToWithdraw1, user3);
        vm.prank(user3);
        uint256 claimedAssets = asyncRedeemer.claimAssets(requestId1);

        assertEq(claimedAssets, assetsToWithdraw1);
        assertEq(accountingToken.balanceOf(user3), claimedAssets);

        uint256 assetsToWithdraw2 = machine.convertToAssets(sharesToRedeem2);

        // Finalize 2nd request
        vm.prank(mechanic);
        asyncRedeemer.finalizeRequests(requestId2, assetsToWithdraw2);

        // User4 claims assets
        vm.expectEmit(true, true, false, true, address(asyncRedeemer));
        emit IAsyncRedeemer.RedeemRequestClaimed(requestId2, sharesToRedeem2, assetsToWithdraw2, user4);
        vm.prank(user4);
        claimedAssets = asyncRedeemer.claimAssets(requestId2);

        assertEq(claimedAssets, assetsToWithdraw2);
        assertEq(accountingToken.balanceOf(user4), claimedAssets);
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

        // Finalize 1st request
        vm.prank(mechanic);
        asyncRedeemer.finalizeRequests(requestId1, assetsToWithdraw1);

        // User1 enters queue again
        uint256 sharesToRedeem3 = mintedShares1 - sharesToRedeem1; // User1 redeems rest of their shares
        vm.startPrank(user1);
        machineShare.approve(address(asyncRedeemer), sharesToRedeem3);
        uint256 requestId3 = asyncRedeemer.requestRedeem(sharesToRedeem3, user3);
        vm.stopPrank();

        skip(asyncRedeemer.finalizationDelay());

        // Generate some negative yield in machine
        deal(address(accountingToken), address(machine), accountingToken.balanceOf(address(machine)) - 1e18);
        machine.updateTotalAum();

        uint256 assetsToWithdraw2 = machine.convertToAssets(sharesToRedeem2);
        uint256 assetsToWithdraw3 = machine.convertToAssets(sharesToRedeem3);

        // Finalize 2nd and 3rd requests
        vm.prank(mechanic);
        asyncRedeemer.finalizeRequests(requestId3, assetsToWithdraw2 + assetsToWithdraw3);

        // User3 claims assets for requestId1
        vm.expectEmit(true, true, false, true, address(asyncRedeemer));
        emit IAsyncRedeemer.RedeemRequestClaimed(requestId1, sharesToRedeem1, assetsToWithdraw1, user3);
        vm.prank(user3);
        uint256 claimedAssets1 = asyncRedeemer.claimAssets(requestId1);

        assertEq(claimedAssets1, assetsToWithdraw1);
        assertEq(accountingToken.balanceOf(user3), claimedAssets1);

        // User3 claims assets for requestId3
        vm.expectEmit(true, true, false, true, address(asyncRedeemer));
        emit IAsyncRedeemer.RedeemRequestClaimed(requestId3, sharesToRedeem3, assetsToWithdraw3, user3);
        vm.prank(user3);
        uint256 claimedAssets3 = asyncRedeemer.claimAssets(requestId3);

        assertEq(claimedAssets3, assetsToWithdraw3);
        assertEq(accountingToken.balanceOf(user3), claimedAssets1 + claimedAssets3);

        // User4 claims assets for requestId2
        vm.expectEmit(true, true, false, true, address(asyncRedeemer));
        emit IAsyncRedeemer.RedeemRequestClaimed(requestId2, sharesToRedeem2, assetsToWithdraw2, user4);
        vm.prank(user4);
        uint256 claimedAssets2 = asyncRedeemer.claimAssets(requestId2);

        assertEq(claimedAssets2, assetsToWithdraw2);
        assertEq(accountingToken.balanceOf(user4), claimedAssets2);
    }

    function test_ClaimAssets_WithWhitelistEnabled() public withWhitelistEnabled withWhitelistedUser(user1) {
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

        // Finalize request
        vm.prank(mechanic);
        asyncRedeemer.finalizeRequests(requestId, assets);

        // User3 tries to claim assets, but is not whitelisted
        vm.expectRevert(CoreErrors.UnauthorizedCaller.selector);
        vm.prank(user3);
        asyncRedeemer.claimAssets(requestId);

        // whitelist User3
        address[] memory users = new address[](1);
        users[0] = user3;
        vm.prank(riskManager);
        asyncRedeemer.setWhitelistedUsers(users, true);

        // User3 claims assets
        vm.expectEmit(true, true, false, true, address(asyncRedeemer));
        emit IAsyncRedeemer.RedeemRequestClaimed(requestId, shares, assets, user3);
        vm.prank(user3);
        uint256 claimedAssets = asyncRedeemer.claimAssets(requestId);

        assertEq(claimedAssets, assets);
        assertEq(accountingToken.balanceOf(user3), claimedAssets);
    }
}
