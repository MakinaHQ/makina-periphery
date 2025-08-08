// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {IMachine} from "@makina-core/interfaces/IMachine.sol";

import {Errors, CoreErrors} from "src/libraries/Errors.sol";
import {IWatermarkFeeManager} from "src/interfaces/IWatermarkFeeManager.sol";
import {MockMachinePeriphery} from "test/mocks/MockMachinePeriphery.sol";

import {WatermarkFeeManager_Integration_Concrete_Test} from "../WatermarkFeeManager.t.sol";

contract CalculateFixedFee_Integration_Concrete_Test is WatermarkFeeManager_Integration_Concrete_Test {
    function test_CalculateFixedFee() public {
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
