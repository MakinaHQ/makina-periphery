// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IMachinePeriphery} from "../interfaces/IMachinePeriphery.sol";

interface ISecurityModule is IMachinePeriphery {
    event Cooldown(address indexed account, uint256 shares, uint256 maturity);
    event CooldownCancelled(address indexed account, uint256 shares);
    event CooldownDurationChanged(uint256 oldCooldownDuration, uint256 newCooldownDuration);
    event MaxSlashableBpsChanged(uint256 oldMaxSlashableBps, uint256 newMaxSlashableBps);
    event MinBalanceAfterSlashChanged(uint256 oldMinBalanceAfterSlash, uint256 newMinBalanceAfterSlash);
    event Lock(address indexed account, address indexed receiver, uint256 assets, uint256 shares);
    event Redeem(address indexed account, address indexed receiver, uint256 assets, uint256 shares);
    event Slash(uint256 amount);
    event SlashingSettled();

    /// @notice Initialization parameters.
    /// @param machineShare Address of the machine share token locked in this contract.
    /// @param initialCooldownDuration Cooldown duration in seconds for unlocking.
    /// @param initialMaxSlashableBps Maximum slashable proportion of the vault balance in basis points.
    /// @param minBalanceAfterSlash Minimum balance that must remain in the vault after a slash.
    struct SecurityModuleInitParams {
        address machineShare;
        uint256 initialCooldownDuration;
        uint256 initialMaxSlashableBps;
        uint256 initialMinBalanceAfterSlash;
    }

    /// @notice Pending cooldown parameters.
    /// @param shares Amount of security shares to be redeemed.
    /// @param maxAssets Maximum amount of machine shares that can be redeemed.
    /// @param maturity Timestamp when the cooldown period ends.
    struct PendingCooldown {
        uint256 shares;
        uint256 maxAssets;
        uint256 maturity;
    }

    /// @notice Address of the machine share token locked in this contract.
    function machineShare() external view returns (address);

    /// @notice Cooldown duration in seconds for unlocking.
    function cooldownDuration() external view returns (uint256);

    /// @notice Maximum slashable proportion of the vault balance in basis points.
    function maxSlashableBps() external view returns (uint256);

    /// @notice Minimum balance that must remain in the vault after a slash.
    function minBalanceAfterSlash() external view returns (uint256);

    /// @notice Account => Pending cooldown data
    function pendingCooldown(address account) external view returns (uint256 shares, uint256 maturity);

    /// @notice Whether the security module is in slashing mode.
    function slashingMode() external view returns (bool);

    /// @notice Total amount of machine shares locked in the module.
    function totalLockedAmount() external view returns (uint256);

    /// @notice Total amount of machine shares currently slashable in the module.
    function maxSlashable() external view returns (uint256);

    /// @notice Converts machine shares to security shares.
    /// @param assets Amount of machine shares to convert.
    /// @return shares Amount of security shares corresponding to the input machine shares.
    function convertToShares(uint256 assets) external view returns (uint256 shares);

    /// @notice Converts security shares to machine shares.
    /// @param shares Amount of security shares to convert.
    /// @return assets Amount of machine shares corresponding to the input security shares.
    function convertToAssets(uint256 shares) external view returns (uint256 assets);

    /// @notice Estimates the amount of security shares that would be received for a given amount of machine shares.
    /// @param assets Amount of machine shares to convert.
    /// @return shares Estimated amount of security shares corresponding to the input machine shares.
    function previewLock(uint256 assets) external view returns (uint256 shares);

    /// @notice Locks machine shares in the module and mints security shares.
    /// @param assets Amount of machine shares to lock.
    /// @param receiver Address that will receive the security shares.
    /// @param minShares Minimum amount of security shares to receive.
    /// @return shares Amount of security shares minted.
    function lock(uint256 assets, address receiver, uint256 minShares) external returns (uint256 shares);

    /// @notice Redeems security shares and transfers machine shares to the receiver.
    /// @param receiver Address that will receive the machine shares.
    /// @param minAssets Minimum amount of machine shares to receive.
    /// @return assets Amount of machine shares transferred to the receiver.
    function redeem(address receiver, uint256 minAssets) external returns (uint256 assets);

    /// @notice Requests a cooldown for redeeming security shares.
    /// @dev Shares are locked in the contract until the cooldown is cancelled or expires.
    /// @param shares Amount of security shares to redeem.
    /// @return maturity Timestamp at which the cooldown period will end and the shares can be redeemed.
    function startCooldown(uint256 shares) external returns (uint256 maturity);

    /// @notice Cancels a pending cooldown.
    /// Shares for which the cooldown was cancelled are transferred back to caller.
    /// @return shares Amount of security shares for which the cooldown was cancelled.
    function cancelCooldown() external returns (uint256 shares);

    /// @notice Slashes a specified amount from the total locked amount and triggers the slashing mode.
    /// @param amount Amount to slash from the total locked amount.
    function slash(uint256 amount) external;

    /// @notice Settles the current slashing, allowing the contract to exit slashing mode and resume normal operations.
    function settleSlashing() external;

    /// @notice Sets the cooldown duration for unlocking.
    /// @param cooldownDuration New cooldown duration in seconds.
    function setCooldownDuration(uint256 cooldownDuration) external;

    /// @notice Sets the maximum slashable proportion of the vault balance in basis points.
    /// @param maxSlashableBps New maximum slashable proportion in basis points.
    function setMaxSlashableBps(uint256 maxSlashableBps) external;

    /// @notice Sets the minimum balance that must remain in the vault after a slash.
    /// @param minBalanceAfterSlash New minimum balance after slash.
    function setMinBalanceAfterSlash(uint256 minBalanceAfterSlash) external;
}
