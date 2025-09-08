/// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

import {AggregatorV2V3Interface} from "@makina-core/interfaces/AggregatorV2V3Interface.sol";
import {Errors} from "@makina-core/libraries/Errors.sol";

/**
 * @title ERC4626Oracle
 * @notice Chainlink-like price oracle wrapping ERC4626 vaults.
 *         This oracle exposes the price of one share of the
 *         vault it wraps in terms of its underlying asset (the exchange rate).
 */
contract ERC4626Oracle is AggregatorV2V3Interface {
    using SafeCast for uint256;

    /// @notice The implementation version of this contract.
    uint256 public immutable version = 1;

    /// @notice The ERC4626 vault.
    IERC4626 public immutable vault;

    /// @notice The underlying asset of the vault.
    IERC20Metadata public immutable underlying;

    /// @notice The number of decimals of the price returned by this oracle.
    uint8 public immutable decimals;

    /// @notice The description for this oracle.
    string public description;

    /// @notice One unit of the ERC4626 vault.
    uint256 public immutable ONE_SHARE;

    /// @notice Scaling factor numerator used to adjust price to the desired decimals.
    uint256 public immutable SCALING_NUMERATOR;

    /// @notice Creates a new ERC4626Wrapper for a given ERC4626 vault.
    /// @param _vault The ERC4626 vault.
    /// @param _decimals The decimals to use for the price.
    constructor(IERC4626 _vault, uint8 _decimals) {
        vault = _vault;
        underlying = IERC20Metadata(_vault.asset());
        uint8 underlyingDecimals = underlying.decimals();

        if (_decimals < underlyingDecimals) {
            revert Errors.InvalidDecimals();
        }
        decimals = _decimals;

        ONE_SHARE = 10 ** _vault.decimals();

        SCALING_NUMERATOR = 10 ** (decimals - underlyingDecimals);

        description = string.concat(vault.symbol(), " / ", underlying.symbol());
    }

    function getPrice() public view returns (uint256) {
        return SCALING_NUMERATOR * vault.convertToAssets(ONE_SHARE);
    }

    //
    // V2 Interface:
    //
    function latestAnswer() external view override returns (int256) {
        return getPrice().toInt256();
    }

    function latestTimestamp() external view override returns (uint256) {
        return block.timestamp;
    }

    function latestRound() external pure override returns (uint256) {
        return 1;
    }

    function getAnswer(uint256) external view override returns (int256) {
        return getPrice().toInt256();
    }

    function getTimestamp(uint256) external view override returns (uint256) {
        return block.timestamp;
    }

    //
    // V3 Interface:
    //
    function getRoundData(uint80)
        external
        view
        override
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return _latestRoundData();
    }

    function latestRoundData()
        external
        view
        override
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return _latestRoundData();
    }

    function _latestRoundData()
        internal
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        uint256 timestamp = block.timestamp;
        return (1, getPrice().toInt256(), timestamp, timestamp, 1);
    }
}
