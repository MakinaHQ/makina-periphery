/// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

interface IWhitelist {
    event UserWhitelistingChanged(address indexed user, bool indexed whitelisted);

    /// @notice User => Whitelisting status.
    function isWhitelistedUser(address user) external view returns (bool);

    /// @notice Whitelist or unwhitelist a list of users.
    /// @param users The addresses of the users to update.
    /// @param whitelisted True to whitelist the users, false to unwhitelist.
    function setWhitelistedUsers(address[] calldata users, bool whitelisted) external;
}
