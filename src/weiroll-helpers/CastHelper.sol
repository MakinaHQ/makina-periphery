// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

contract CastHelper {
    /// @notice See {SafeCast-toUint256}.
    function int256ToUint256(int256 value) external pure returns (uint256) {
        return SafeCast.toUint256(value);
    }

    /// @notice See {SafeCast-toInt256}.
    function uint256ToInt256(uint256 value) external pure returns (int256) {
        return SafeCast.toInt256(value);
    }

    /// @notice Cast a bytes value to its string representation.
    function bytesToString(bytes calldata b) external pure returns (string memory) {
        return string(abi.encodePacked(b));
    }
}
