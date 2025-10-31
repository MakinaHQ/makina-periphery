// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

contract BooleanHelper {
    error ConditionIsTrue();
    error ConditionIsFalse();

    /// @notice logical NOT operation
    function not(bool x) external pure returns (bool) {
        return !x;
    }

    /// @notice logical AND operation
    function and(bool x, bool y) external pure returns (bool) {
        return x && y;
    }

    /// @notice logical OR operation
    function or(bool x, bool y) external pure returns (bool) {
        return x || y;
    }

    /// @notice Reverts if the condition is true.
    function revertIfTrue(bool x) external pure {
        if (x) {
            revert ConditionIsTrue();
        }
    }

    /// @notice Reverts if the condition is false.
    function revertIfFalse(bool x) external pure {
        if (!x) {
            revert ConditionIsFalse();
        }
    }
}
