// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {SignedMath} from "@openzeppelin/contracts/utils/math/SignedMath.sol";

contract SignedMathHelper {
    /// @notice Returns the addition of two int256.
    function add(int256 a, int256 b) external pure returns (int256) {
        return a + b;
    }

    /// @notice Returns the subtraction of two int256.
    function sub(int256 a, int256 b) external pure returns (int256) {
        return a - b;
    }

    /// @notice Returns the multiplication of two int256.
    function mul(int256 a, int256 b) external pure returns (int256) {
        return a * b;
    }

    /// @notice Returns the division of two int256.
    function div(int256 a, int256 b) external pure returns (int256) {
        return a / b;
    }

    /// @dev See {SignedMath-max}.
    function max(int256 a, int256 b) external pure returns (int256) {
        return SignedMath.max(a, b);
    }

    /// @dev See {SignedMath-min}.
    function min(int256 a, int256 b) external pure returns (int256) {
        return SignedMath.min(a, b);
    }

    /// @dev See {SignedMath-average}.
    function average(int256 a, int256 b) external pure returns (int256) {
        return SignedMath.average(a, b);
    }

    /// @dev See {SignedMath-abs}.
    function abs(int256 a) external pure returns (uint256) {
        return SignedMath.abs(a);
    }
}
