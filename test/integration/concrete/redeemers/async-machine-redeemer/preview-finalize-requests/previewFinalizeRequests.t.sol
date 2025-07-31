// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

import {Errors} from "src/libraries/Errors.sol";

import {AsyncMachineRedeemer_Integration_Concrete_Test} from "../AsyncMachineRedeemer.t.sol";

contract PreviewFinalizeRequests_Integration_Concrete_Test is AsyncMachineRedeemer_Integration_Concrete_Test {
    function test_RevertWhen_NonExistentRequest() public withMachine(address(machine)) {
        uint256 requestId = 1;
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, requestId));
        vm.prank(mechanic);
        asyncMachineRedeemer.previewFinalizeRequests(requestId);
    }

    function test_RevertWhen_RequestAlreadyFinalized() public withMachine(address(machine)) {
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

        // Finalize requests
        vm.prank(mechanic);
        asyncMachineRedeemer.finalizeRequests(requestId, 0);

        // Revert if trying to finalize again
        vm.expectRevert(Errors.AlreadyFinalized.selector);
        vm.prank(mechanic);
        asyncMachineRedeemer.previewFinalizeRequests(requestId);
    }

    function test_PreviewFinalizeRequests_OneUser_OneSimultaneousSlot() public withMachine(address(machine)) {
        uint256 inputAssets1 = 3e18;

        // Deposit assets to the machine
        deal(address(accountingToken), machineDepositorAddr, inputAssets1);
        vm.startPrank(machineDepositorAddr);
        IERC20(accountingToken).approve(address(machine), inputAssets1);
        uint256 mintedShares1 = machine.deposit(inputAssets1, user1, 0);
        vm.stopPrank();

        // User1 enters queue
        uint256 sharesToRedeem1 = mintedShares1 / 3; // User1 redeems part of their shares
        uint256 assetsToWithdraw1 = machine.convertToAssets(sharesToRedeem1);
        vm.startPrank(user1);
        machineShare.approve(address(asyncMachineRedeemer), sharesToRedeem1);
        uint256 requestId1 = asyncMachineRedeemer.requestRedeem(sharesToRedeem1, user3);
        vm.stopPrank();

        // Generate some positive yield in machine
        deal(address(accountingToken), address(machine), accountingToken.balanceOf(address(machine)) + 1e17);
        machine.updateTotalAum();

        (uint256 previewTotalShares, uint256 previewTotalAssets) =
            asyncMachineRedeemer.previewFinalizeRequests(requestId1);

        assertEq(previewTotalShares, sharesToRedeem1);
        assertEq(previewTotalAssets, assetsToWithdraw1);

        // Finalize 1st request
        vm.prank(mechanic);
        (uint256 totalShares, uint256 totalAssets) =
            asyncMachineRedeemer.finalizeRequests(requestId1, assetsToWithdraw1);

        assertEq(previewTotalShares, totalShares);
        assertEq(previewTotalAssets, totalAssets);

        // User1 enters queue again
        uint256 sharesToRedeem2 = mintedShares1 - sharesToRedeem1; // User1 redeems rest of their shares
        vm.startPrank(user1);
        machineShare.approve(address(asyncMachineRedeemer), sharesToRedeem2);
        uint256 requestId2 = asyncMachineRedeemer.requestRedeem(sharesToRedeem2, user3);
        vm.stopPrank();

        // Generate some negative yield in machine
        deal(address(accountingToken), address(machine), accountingToken.balanceOf(address(machine)) - 1e18);
        machine.updateTotalAum();

        uint256 assetsToWithdraw2 = machine.convertToAssets(sharesToRedeem2);

        (previewTotalShares, previewTotalAssets) = asyncMachineRedeemer.previewFinalizeRequests(requestId2);

        assertEq(previewTotalShares, sharesToRedeem2);
        assertEq(previewTotalAssets, assetsToWithdraw2);

        // Finalize 2nd request
        vm.prank(mechanic);
        (totalShares, totalAssets) = asyncMachineRedeemer.finalizeRequests(requestId2, assetsToWithdraw2);

        assertEq(previewTotalShares, totalShares);
        assertEq(previewTotalAssets, totalAssets);
    }

    function test_PreviewFinalizeRequests_OneUser_TwoSimultaneousSlots() public withMachine(address(machine)) {
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
        uint256 assetsToWithdraw2 = machine.convertToAssets(sharesToRedeem2);
        vm.startPrank(user1);
        machineShare.approve(address(asyncMachineRedeemer), sharesToRedeem2);
        uint256 requestId2 = asyncMachineRedeemer.requestRedeem(sharesToRedeem2, user3);
        vm.stopPrank();

        (uint256 previewTotalShares, uint256 previewTotalAssets) =
            asyncMachineRedeemer.previewFinalizeRequests(requestId2);

        assertEq(previewTotalShares, sharesToRedeem1 + sharesToRedeem2);
        assertEq(previewTotalAssets, assetsToWithdraw1 + assetsToWithdraw2);

        (previewTotalShares, previewTotalAssets) = asyncMachineRedeemer.previewFinalizeRequests(requestId1);

        assertEq(previewTotalShares, sharesToRedeem1);
        assertEq(previewTotalAssets, assetsToWithdraw1);

        // Finalize 1st request
        vm.prank(mechanic);
        (uint256 totalShares, uint256 totalAssets) =
            asyncMachineRedeemer.finalizeRequests(requestId1, assetsToWithdraw1);

        assertEq(previewTotalShares, totalShares);
        assertEq(previewTotalAssets, totalAssets);

        // Generate some negative yield in machine
        deal(address(accountingToken), address(machine), accountingToken.balanceOf(address(machine)) - 1e18);
        machine.updateTotalAum();

        assetsToWithdraw2 = machine.convertToAssets(sharesToRedeem2);

        (previewTotalShares, previewTotalAssets) = asyncMachineRedeemer.previewFinalizeRequests(requestId2);

        assertEq(previewTotalAssets, assetsToWithdraw2);

        // Finalize 2nd request
        vm.prank(mechanic);
        (totalShares, totalAssets) = asyncMachineRedeemer.finalizeRequests(requestId2, assetsToWithdraw2);

        assertEq(previewTotalShares, totalShares);
        assertEq(previewTotalAssets, totalAssets);
    }

    function test_PreviewFinalizeRequests_TwoUsers() public withMachine(address(machine)) {
        uint256 inputAssets1 = 1e18;
        uint256 inputAssets2 = 2e18;

        // Deposit assets to the machine
        deal(address(accountingToken), machineDepositorAddr, inputAssets1 + inputAssets2);
        vm.startPrank(machineDepositorAddr);
        IERC20(accountingToken).approve(address(machine), inputAssets1 + inputAssets2);
        uint256 mintedShares1 = machine.deposit(inputAssets1, user1, 0);
        uint256 mintedShares2 = machine.deposit(inputAssets2, user2, 0);
        vm.stopPrank();

        // User1 enters queue
        uint256 sharesToRedeem1 = mintedShares1 / 3; // User1 redeems part of their shares
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
        uint256 assetsToWithdraw2 = machine.convertToAssets(sharesToRedeem2);
        vm.startPrank(user2);
        machineShare.approve(address(asyncMachineRedeemer), sharesToRedeem2);
        uint256 requestId2 = asyncMachineRedeemer.requestRedeem(sharesToRedeem2, user4);
        vm.stopPrank();

        (uint256 previewTotalShares, uint256 previewTotalAssets) =
            asyncMachineRedeemer.previewFinalizeRequests(requestId2);

        assertEq(previewTotalShares, sharesToRedeem1 + sharesToRedeem2);
        assertEq(previewTotalAssets, assetsToWithdraw1 + assetsToWithdraw2);

        (previewTotalShares, previewTotalAssets) = asyncMachineRedeemer.previewFinalizeRequests(requestId1);

        assertEq(previewTotalShares, sharesToRedeem1);
        assertEq(previewTotalAssets, assetsToWithdraw1);

        // Finalize 1st request
        vm.prank(mechanic);
        (uint256 totalShares, uint256 totalAssets) =
            asyncMachineRedeemer.finalizeRequests(requestId1, assetsToWithdraw1);

        assertEq(previewTotalShares, totalShares);
        assertEq(previewTotalAssets, totalAssets);

        // Generate some negative yield in machine
        deal(address(accountingToken), address(machine), accountingToken.balanceOf(address(machine)) - 1e18);
        machine.updateTotalAum();

        // User1 enters queue again
        sharesToRedeem1 = mintedShares1 - sharesToRedeem1; // User1 redeems rest of their shares
        assetsToWithdraw1 = machine.convertToAssets(sharesToRedeem1);
        vm.startPrank(user1);
        machineShare.approve(address(asyncMachineRedeemer), sharesToRedeem1);
        uint256 requestId3 = asyncMachineRedeemer.requestRedeem(sharesToRedeem1, user3);
        vm.stopPrank();

        (previewTotalShares, previewTotalAssets) = asyncMachineRedeemer.previewFinalizeRequests(requestId2);
        assertEq(previewTotalShares, sharesToRedeem2);
        assertLt(previewTotalAssets, assetsToWithdraw2);

        assetsToWithdraw2 = machine.convertToAssets(sharesToRedeem2);

        (previewTotalShares, previewTotalAssets) = asyncMachineRedeemer.previewFinalizeRequests(requestId3);
        assertEq(previewTotalShares, sharesToRedeem2 + sharesToRedeem1);
        assertEq(previewTotalAssets, assetsToWithdraw2 + assetsToWithdraw1);

        // Finalize 2nd and 3rd requests
        vm.prank(mechanic);
        (totalShares, totalAssets) =
            asyncMachineRedeemer.finalizeRequests(requestId3, assetsToWithdraw2 + assetsToWithdraw1);

        assertEq(previewTotalShares, totalShares);
        assertEq(previewTotalAssets, totalAssets);
    }
}
