// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ICaliber} from "@makina-core/interfaces/ICaliber.sol";

/// @title IFlashloanAggregator
/// @notice The interface for the flashloan aggregator.
interface IFlashloanAggregator {
    /// @notice Error thrown when the caller is not a Caliber.
    error NotCaliber();

    /// @notice Error thrown when the initiator is not the requested contract.
    error NotRequested();

    /// @notice Error thrown when the token is invalid.
    error InvalidToken();

    /// @notice Error thrown when params length is invalid.
    error InvalidParamsLength();

    /// @notice Error thrown when the fee amount is invalid.
    error InvalidFeeAmount();

    /// @notice Error thrown when the caller is not the Balancer V2 pool.
    error NotBalancerV2Pool();

    /// @notice Error thrown when the caller is not the Balancer V3 pool.
    error NotBalancerV3Pool();

    /// @notice Error thrown when the caller is not the Morpho pool.
    error NotMorpho();

    /// @notice Error thrown when the caller is not the Maker DSS Flash.
    error NotDssFlash();

    /// @notice Error thrown when the caller is not the Aave V3 pool.
    error NotAaveV3Pool();

    /// @notice Error thrown when the Balancer V2 pool is not set.
    error BalancerV2PoolNotSet();

    /// @notice Error thrown when the Balancer V3 pool is not set.
    error BalancerV3PoolNotSet();

    /// @notice Error thrown when the Morpho pool is not set.
    error MorphoPoolNotSet();

    /// @notice Error thrown when the Maker DSS Flash is not set.
    error DssFlashNotSet();

    /// @notice Error thrown when the Aave V3 pool is not set.
    error AaveV3PoolNotSet();

    /// @notice Error thrown when the user data hash is invalid.
    error InvalidUserDataHash();

    /// @notice The enum for the flashloan providers.
    enum FlashloanProvider {
        /// Aave V3
        AAVE_V3,
        /// Balancer V2
        BALANCER_V2,
        /// Balancer V3
        BALANCER_V3,
        /// Morpho
        MORPHO,
        /// Maker DSS Flash
        DSS_FLASH
    }

    /// @notice The struct for requesting a flashloan.
    /// @param provider The provider of the flashloan.
    /// @param instruction The instruction to execute.
    /// @param token The token to borrow.
    /// @param amount The amount to borrow.
    struct FlashloanRequest {
        FlashloanProvider provider;
        ICaliber.Instruction instruction;
        address token;
        uint256 amount;
    }

    /// @notice The function to request a flashloan.
    /// @param request The request for the flashloan.
    function requestFlashloan(FlashloanRequest calldata request) external;
}
