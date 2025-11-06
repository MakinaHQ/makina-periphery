// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

contract Bytes32Helper {
    error IndexOutOfBounds();

    // bytes4(keccak256("IndexOutOfBounds()"))
    bytes4 private constant _INDEX_OUT_OF_BOUNDS_SELECTOR = 0x4e23d035;

    /// @notice Returns whether two values are equal.
    function eq(bytes32 a, bytes32 b) external pure returns (bool) {
        return a == b;
    }

    /// @notice Ternary evaluation for bytes32 type.
    function ternary(bool condition, bytes32 a, bytes32 b) external pure returns (bytes32) {
        return condition ? a : b;
    }

    /// @notice Returns an array from the two given values.
    function arrayOf(bytes32 a, bytes32 b) external pure returns (bytes32[] memory) {
        assembly {
            let p := mload(0x40)
            mstore(p, 0x20)
            mstore(add(p, 0x20), 2)
            mstore(add(p, 0x40), a)
            mstore(add(p, 0x60), b)
            return(p, 0x80)
        }
    }

    /// @notice Returns the 32-byte word at a given index from a bytes-encoded tuple of consecutive 32-byte static values.
    function getTupleWord(bytes memory tuple, uint256 index) public pure returns (bytes32) {
        assembly {
            let len := mload(tuple)
            if iszero(lt(index, shr(5, len))) {
                mstore(0x00, _INDEX_OUT_OF_BOUNDS_SELECTOR)
                revert(0x00, 0x04)
            }
            mstore(0x00, mload(add(add(tuple, 0x20), shl(5, index))))
            return(0x00, 0x20)
        }
    }

    /// @notice Returns the 32-byte word at a given index from a dynamic array.
    function getArrayWord(bytes32[] memory arr, uint256 index) public pure returns (bytes32) {
        assembly {
            if iszero(lt(index, mload(arr))) {
                mstore(0x00, _INDEX_OUT_OF_BOUNDS_SELECTOR)
                revert(0x00, 0x04)
            }
            mstore(0x00, mload(add(add(arr, 0x20), shl(5, index))))
            return(0x00, 0x20)
        }
    }
}
