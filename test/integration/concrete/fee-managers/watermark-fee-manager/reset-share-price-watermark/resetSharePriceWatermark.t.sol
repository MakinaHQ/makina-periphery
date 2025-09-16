// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {IAccessManaged} from "@openzeppelin/contracts/access/manager/IAccessManaged.sol";

import {Errors} from "src/libraries/Errors.sol";

import {WatermarkFeeManager_Integration_Concrete_Test} from "../WatermarkFeeManager.t.sol";

contract ResetSharePriceWatermark_Integration_Concrete_Test is WatermarkFeeManager_Integration_Concrete_Test {
    function setUp() public override {
        WatermarkFeeManager_Integration_Concrete_Test.setUp();

        vm.prank(dao);
        hubPeripheryFactory.setMachine(address(watermarkFeeManager), address(machine));
    }

    function test_ResetSharePriceWatermark_RevertWhen_CallerWithoutRole() public {
        vm.expectRevert(abi.encodeWithSelector(IAccessManaged.AccessManagedUnauthorized.selector, address(this)));
        watermarkFeeManager.resetSharePriceWatermark(0);
    }

    function test_ResetSharePriceWatermark_RevertWhen_ValueGreaterThanCurrentWatermark() public {
        vm.expectRevert(Errors.GreaterThanCurrentWatermark.selector);
        vm.prank(dao);
        watermarkFeeManager.resetSharePriceWatermark(1);

        uint256 sharePrice1 = 1e18;

        vm.prank(address(machine));
        watermarkFeeManager.calculatePerformanceFee(1e25, 0, sharePrice1, 0);

        vm.expectRevert(Errors.GreaterThanCurrentWatermark.selector);
        vm.prank(dao);
        watermarkFeeManager.resetSharePriceWatermark(sharePrice1 + 1);
    }

    function test_ResetSharePriceWatermark() public {
        uint256 currentShareSupply = 1e25;

        uint256 sharePrice1 = 3e18;
        uint256 sharePrice2 = 1e18;
        uint256 sharePrice3 = 2e18;

        vm.prank(address(machine));
        watermarkFeeManager.calculatePerformanceFee(1e25, 0, sharePrice1, 0);

        vm.prank(dao);
        watermarkFeeManager.resetSharePriceWatermark(sharePrice2);

        assertEq(watermarkFeeManager.sharePriceWatermark(), sharePrice2);

        vm.prank(address(machine));
        uint256 fee = watermarkFeeManager.calculatePerformanceFee(1e25, 0, sharePrice3, 0);

        assertEq(
            fee,
            currentShareSupply * (sharePrice3 - sharePrice2) * watermarkFeeManager.perfFeeRate() / (sharePrice3 * 1e18)
        );
        assertEq(watermarkFeeManager.sharePriceWatermark(), sharePrice3);
    }
}
