// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IMachinePeriphery} from "./IMachinePeriphery.sol";

interface IDirectDepositor is IMachinePeriphery {
    /// @notice Deposits accounting tokens into the machine and mints shares to the receiver.
    /// @param assets The amount of accounting tokens to deposit.
    /// @param receiver The receiver of minted shares.
    /// @param minShares The minimum amount of shares to be minted.
    /// @param referralKey The optional identifier used to track a referral source.
    /// @return shares The amount of shares minted.
    function deposit(uint256 assets, address receiver, uint256 minShares, bytes32 referralKey)
        external
        returns (uint256);
}
