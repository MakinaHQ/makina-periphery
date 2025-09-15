// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {WatermarkFeeManager_Integration_Concrete_Test} from "../WatermarkFeeManager.t.sol";

contract CalculateFixedFee_Integration_Concrete_Test is WatermarkFeeManager_Integration_Concrete_Test {
    function test_CalculateFixedFee_NoStakingModule() public {
        uint256 currentShareSupply = 1e25;
        uint256 elapsedTime = 1 days;

        uint256 fee1 = watermarkFeeManager.calculateFixedFee(currentShareSupply, elapsedTime);

        assertEq(fee1, currentShareSupply * elapsedTime * (watermarkFeeManager.mgmtFeeRatePerSecond()) / 1e18);

        elapsedTime = 2 days;

        uint256 fee2 = watermarkFeeManager.calculateFixedFee(currentShareSupply, elapsedTime);

        assertEq(fee2, 2 * fee1);

        currentShareSupply = 2 * 1e25;

        uint256 fee3 = watermarkFeeManager.calculateFixedFee(currentShareSupply, elapsedTime);

        assertEq(fee3, 2 * fee2);
    }

    function test_CalculateFixedFee_WithStakingModule() public {
        vm.startPrank(dao);
        hubPeripheryFactory.setMachine(address(watermarkFeeManager), address(machine));
        hubPeripheryFactory.setSecurityModule(address(watermarkFeeManager), securityModuleAddr);
        vm.stopPrank();

        uint256 currentShareSupply = 1e25;
        uint256 elapsedTime = 1 days;

        uint256 fee1 = watermarkFeeManager.calculateFixedFee(currentShareSupply, elapsedTime);

        assertEq(
            fee1,
            currentShareSupply * elapsedTime
                * (watermarkFeeManager.mgmtFeeRatePerSecond() + watermarkFeeManager.smFeeRatePerSecond()) / 1e18
        );

        elapsedTime = 2 days;

        uint256 fee2 = watermarkFeeManager.calculateFixedFee(currentShareSupply, elapsedTime);

        assertEq(fee2, 2 * fee1);

        currentShareSupply = 2 * 1e25;

        uint256 fee3 = watermarkFeeManager.calculateFixedFee(currentShareSupply, elapsedTime);

        assertEq(fee3, 2 * fee2);
    }
}
