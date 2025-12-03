// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

contract MathHelper {
    error DecimalsOutOfRange();

    /// @notice Returns the addition of two uint256.
    function add(uint256 a, uint256 b) external pure returns (uint256) {
        return a + b;
    }

    /// @notice Returns the subtraction of two uint256.
    function sub(uint256 a, uint256 b) external pure returns (uint256) {
        return a - b;
    }

    /// @notice Returns the multiplication of two uint256.
    function mul(uint256 a, uint256 b) external pure returns (uint256) {
        return a * b;
    }

    /// @notice Returns the division of two uint256.
    function div(uint256 a, uint256 b) external pure returns (uint256) {
        return a / b;
    }

    /// @notice See {Math-ceilDiv}.
    function ceilDiv(uint256 a, uint256 b) external pure returns (uint256) {
        return Math.ceilDiv(a, b);
    }

    /// @notice See {Math-mulDiv}.
    function mulDiv(uint256 x, uint256 y, uint256 denominator) external pure returns (uint256) {
        return Math.mulDiv(x, y, denominator);
    }

    /// @notice See {Math-mulDiv}.
    function ceilMulDiv(uint256 x, uint256 y, uint256 denominator) external pure returns (uint256) {
        return Math.mulDiv(x, y, denominator, Math.Rounding.Ceil);
    }

    /// @notice See {Math-sqrt}.
    function sqrt(uint256 a) external pure returns (uint256) {
        return Math.sqrt(a);
    }

    /// @notice See {Math-average}.
    function average(uint256 a, uint256 b) external pure returns (uint256) {
        return Math.average(a, b);
    }

    /// @notice See {Math-ternary}.
    function ternary(bool condition, uint256 a, uint256 b) external pure returns (uint256) {
        return Math.ternary(condition, a, b);
    }

    /// @notice See {Math-max}.
    function max(uint256 a, uint256 b) external pure returns (uint256) {
        return Math.max(a, b);
    }

    /// @notice See {Math-min}.
    function min(uint256 a, uint256 b) external pure returns (uint256) {
        return Math.min(a, b);
    }

    /// @notice See {Math-log2}.
    function log2(uint256 x) external pure returns (uint256 r) {
        return Math.log2(x);
    }

    /// @notice See {Math-log10}.
    function log10(uint256 x) external pure returns (uint256 r) {
        return Math.log10(x);
    }

    /// @notice See {Math-log256}.
    function log256(uint256 x) external pure returns (uint256 r) {
        return Math.log256(x);
    }

    /// @notice Returns whether two values are equal.
    function eq(uint256 a, uint256 b) external pure returns (bool) {
        return a == b;
    }

    /// @notice Returns whether a value is less than another value.
    function lt(uint256 a, uint256 b) external pure returns (bool) {
        return a < b;
    }

    /// @notice Returns whether a value is less than or equal to another value.
    function lte(uint256 a, uint256 b) external pure returns (bool) {
        return a <= b;
    }

    /// @notice Returns whether a value is greater than another value.
    function gt(uint256 a, uint256 b) external pure returns (bool) {
        return a > b;
    }

    /// @notice Returns whether a value is greater than or equal to another value.
    function gte(uint256 a, uint256 b) external pure returns (bool) {
        return a >= b;
    }

    /// @notice Returns the maximum value of uint128.
    function uint128Max() external pure returns (uint128) {
        return type(uint128).max;
    }

    /// @notice Returns the maximum value of uint256.
    function uint256Max() external pure returns (uint256) {
        return type(uint256).max;
    }

    /// @notice Scales `amount` from `fromDecimals` to `toDecimals`.
    /// @dev Converts token amounts between different decimal precisions.
    /// @param amount The amount to scale.
    /// @param fromDecimals The source decimal precision.
    /// @param toDecimals The target decimal precision.
    /// @return scaled The amount adjusted to the target decimals.
    /// @custom:warning Scaling down reduces precision due to integer division truncation.
    function scaleAmount(uint256 amount, uint8 fromDecimals, uint8 toDecimals) public pure returns (uint256 scaled) {
        if (fromDecimals > 77 || toDecimals > 77) {
            revert DecimalsOutOfRange();
        }

        uint256 factor;
        unchecked {
            factor = 10 ** uint256(fromDecimals > toDecimals ? fromDecimals - toDecimals : toDecimals - fromDecimals);
        }

        return fromDecimals < toDecimals ? amount * factor : amount / factor;
    }
}
