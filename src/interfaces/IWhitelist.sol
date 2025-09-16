// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface IWhitelist {
    event UserWhitelistingChanged(address indexed user, bool indexed whitelisted);
    event WhitelistStatusChanged(bool indexed enabled);

    /// @notice True if whitelist is enabled, false otherwise.
    function isWhitelistEnabled() external view returns (bool);

    /// @notice User => Whitelisting status.
    function isWhitelistedUser(address user) external view returns (bool);

    /// @notice Enables or disables the whitelist.
    /// @param enabled True to enable the whitelist, false to disable.
    function setWhitelistStatus(bool enabled) external;

    /// @notice Whitelists or unwhitelists a list of users.
    /// @param users The addresses of the users to update.
    /// @param whitelisted True to whitelist the users, false to unwhitelist.
    function setWhitelistedUsers(address[] calldata users, bool whitelisted) external;
}
