// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IAsyncRedeemer} from "./IAsyncRedeemer.sol";

interface IAsyncRedeemerFee is IAsyncRedeemer {
    event RedeemFeeRateChanged(uint256 oldRate, uint256 newRate);

    /// @notice Redeem fee rate. 1e18 = 100%.
    function redeemFeeRate() external view returns (uint256);

    /// @notice Sets the redeem fee rate.
    /// @param newRedeemFeeRate The new redeem fee rate. 1e18 = 100%.
    function setRedeemFeeRate(uint256 newRedeemFeeRate) external;
}
