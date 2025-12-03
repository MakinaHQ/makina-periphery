// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

contract KeyValueStore {
    error NotOwner();

    /// @notice Owner of the contract.
    address public immutable caliber;

    /// @dev Internal key-value storage mapping.
    mapping(bytes32 key => bytes32 value) private _store;

    modifier onlyCaliber() {
        if (msg.sender != caliber) {
            revert NotOwner();
        }
        _;
    }

    constructor(address _caliber) {
        caliber = _caliber;
    }

    /// @notice Stores a value associated with a specific key.
    /// @param key The key to associate with the value.
    /// @param value The value to be stored for the given key.
    function set(bytes32 key, bytes32 value) external onlyCaliber {
        _store[key] = value;
    }

    /// @notice Returns the value associated with a specific key.
    /// @param key The key whose value to retrieve.
    /// @return value The value associated with the provided key.
    function get(bytes32 key) external view returns (bytes32) {
        return _store[key];
    }

    /// @notice Deletes the value associated with a specific key.
    /// @param key The key whose value to delete.
    function reset(bytes32 key) external onlyCaliber {
        delete _store[key];
    }
}
