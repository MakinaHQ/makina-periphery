// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

contract ContextHelper {
    /// @notice Returns the current block timestamp.
    function blockTimestamp() external view returns (uint256) {
        return block.timestamp;
    }

    /// @notice Returns the current block number.
    function blockNumber() external view returns (uint256) {
        return block.number;
    }

    /// @notice Returns the msg.sender.
    function msgSender() external view returns (address) {
        return msg.sender;
    }

    /// @notice Returns the balance of an account.
    function balance(address account) external view returns (uint256) {
        return account.balance;
    }
}
