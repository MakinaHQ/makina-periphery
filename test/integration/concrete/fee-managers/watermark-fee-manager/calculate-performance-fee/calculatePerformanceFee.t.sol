// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {CoreErrors} from "src/libraries/Errors.sol";

import {WatermarkFeeManager_Integration_Concrete_Test} from "../WatermarkFeeManager.t.sol";

contract CalculatePerformanceFee_Integration_Concrete_Test is WatermarkFeeManager_Integration_Concrete_Test {
    function setUp() public override {
        WatermarkFeeManager_Integration_Concrete_Test.setUp();

        vm.prank(dao);
        hubPeripheryFactory.setMachine(address(watermarkFeeManager), address(machine));
    }

    function test_RevertWhen_CallerNotMachine() public {
        vm.expectRevert(CoreErrors.NotMachine.selector);
        watermarkFeeManager.calculatePerformanceFee(0, 0, 0, 0);
    }

    function test_CalculatePerformanceFee_NoWatermark() public {
        uint256 currentShareSupply = 1e25;
        uint256 newSharePrice = 2e18;

        vm.prank(address(machine));
        uint256 fee = watermarkFeeManager.calculatePerformanceFee(currentShareSupply, 0, newSharePrice, 0);

        assertEq(fee, 0);
        assertEq(watermarkFeeManager.sharePriceWatermark(), newSharePrice);
    }

    function test_CalculatePerformanceFee_PriceIncrease() public {
        uint256 currentShareSupply = 1e25;
        uint256 sharePrice1 = 1e18;
        uint256 sharePrice2 = 2e18;

        vm.startPrank(address(machine));
        watermarkFeeManager.calculatePerformanceFee(currentShareSupply, 0, sharePrice1, 0);
        uint256 fee = watermarkFeeManager.calculatePerformanceFee(currentShareSupply, 0, sharePrice2, 0);

        assertEq(
            fee,
            currentShareSupply * (sharePrice2 - sharePrice1) * watermarkFeeManager.perfFeeRate() / (sharePrice2 * 1e18)
        );
        assertEq(watermarkFeeManager.sharePriceWatermark(), sharePrice2);
    }

    function test_CalculatePerformanceFee_PriceDecrease() public {
        uint256 currentShareSupply = 1e25;
        uint256 sharePrice1 = 2e18;
        uint256 sharePrice2 = 1e18;

        vm.startPrank(address(machine));
        watermarkFeeManager.calculatePerformanceFee(currentShareSupply, 0, sharePrice1, 0);
        uint256 fee = watermarkFeeManager.calculatePerformanceFee(currentShareSupply, 0, sharePrice2, 0);

        assertEq(fee, 0);
        assertEq(watermarkFeeManager.sharePriceWatermark(), sharePrice1);
    }

    function test_CalculatePerformanceFee_NoPriceChange() public {
        uint256 currentShareSupply = 1e25;
        uint256 sharePrice1 = 1e18;
        uint256 sharePrice2 = sharePrice1;

        vm.startPrank(address(machine));
        watermarkFeeManager.calculatePerformanceFee(currentShareSupply, 0, sharePrice1, 0);
        uint256 fee = watermarkFeeManager.calculatePerformanceFee(currentShareSupply, 0, sharePrice2, 0);

        assertEq(fee, 0);
        assertEq(watermarkFeeManager.sharePriceWatermark(), sharePrice1);
    }
}
