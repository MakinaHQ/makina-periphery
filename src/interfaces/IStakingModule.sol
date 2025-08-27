// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IMachinePeriphery} from "../interfaces/IMachinePeriphery.sol";

interface IStakingModule is IMachinePeriphery {
    event Cooldown(address indexed account, uint256 shares, uint256 maturity);
    event CooldownDurationChanged(uint256 oldCooldownDuration, uint256 newCooldownDuration);
    event MaxSlashableBpsChanged(uint256 oldMaxSlashableBps, uint256 newMaxSlashableBps);
    event MinBalanceAfterSlashChanged(uint256 oldMinBalanceAfterSlash, uint256 newMinBalanceAfterSlash);
    event Stake(address indexed account, address indexed receiver, uint256 assets, uint256 shares);
    event Redeem(address indexed account, address indexed receiver, uint256 assets, uint256 shares);
    event Slash(uint256 amount);
    event SlashingSettled();

    /// @notice Initialization parameters.
    /// @param machineShare Address of the machine share token staked in this contract.
    /// @param initialCooldownDuration Cooldown duration in seconds for unstaking.
    /// @param initialMaxSlashableBps Maximum slashable proportion of the vault balance in basis points.
    /// @param minBalanceAfterSlash Minimum balance that must remain in the vault after a slash.
    struct StakingModuleInitParams {
        address machineShare;
        uint256 initialCooldownDuration;
        uint256 initialMaxSlashableBps;
        uint256 initialMinBalanceAfterSlash;
    }

    /// @notice Pending cooldown parameters.
    /// @param shares Amount of staking shares to be redeemed.
    /// @param maxAssets Maximum amount of machine shares that can be redeemed.
    /// @param maturity Timestamp when the cooldown period ends.
    struct PendingCooldown {
        uint256 shares;
        uint256 maxAssets;
        uint256 maturity;
    }

    /// @notice Address of the machine share token staked in this contract.
    function machineShare() external view returns (address);

    /// @notice Cooldown duration in seconds for unstaking.
    function cooldownDuration() external view returns (uint256);

    /// @notice Maximum slashable proportion of the vault balance in basis points.
    function maxSlashableBps() external view returns (uint256);

    /// @notice Minimum balance that must remain in the vault after a slash.
    function minBalanceAfterSlash() external view returns (uint256);

    /// @notice Account => Pending cooldown data
    function pendingCooldown(address account) external view returns (uint256 shares, uint256 maturity);

    /// @notice Whether the staking module is in slashing mode.
    function slashingMode() external view returns (bool);

    /// @notice Total amount of machine shares staked in the module.
    function totalStakedAmount() external view returns (uint256);

    /// @notice Total amount of machine shares currently slashable in the module.
    function maxSlashable() external view returns (uint256);

    /// @notice Converts machine shares to staking shares.
    /// @param assets Amount of machine shares to convert.
    /// @return shares Amount of staking shares corresponding to the input machine shares.
    function convertToShares(uint256 assets) external view returns (uint256 shares);

    /// @notice Converts staking shares to machine shares.
    /// @param shares Amount of staking shares to convert.
    /// @return assets Amount of machine shares corresponding to the input staking shares.
    function convertToAssets(uint256 shares) external view returns (uint256 assets);

    /// @notice Estimates the amount of staking shares that would be received for a given amount of machine shares.
    /// @param assets Amount of machine shares to convert.
    /// @return shares Estimated amount of staking shares corresponding to the input machine shares.
    function previewStake(uint256 assets) external view returns (uint256 shares);

    /// @notice Stakes machine shares in the module and mints staking shares.
    /// @param assets Amount of machine shares to stake.
    /// @param receiver Address that will receive the staking shares.
    /// @param minShares Minimum amount of staking shares to receive.
    /// @return shares Amount of staking shares minted.
    function stake(uint256 assets, address receiver, uint256 minShares) external returns (uint256 shares);

    /// @notice Redeems staking shares and transfers machine shares to the receiver.
    /// @param receiver Address that will receive the machine shares.
    /// @param minAssets Minimum amount of machine shares to receive.
    /// @return assets Amount of machine shares transferred to the receiver.
    function redeem(address receiver, uint256 minAssets) external returns (uint256 assets);

    /// @notice Requests a cooldown for redeeming staking shares.
    /// @param shares Amount of staking shares to redeem.
    /// @return maturity Timestamp at which the cooldown period will end and the shares can be redeemed.
    function startCooldown(uint256 shares) external returns (uint256 maturity);

    /// @notice Slashes a specified amount from the total staked amount and triggers the slashing mode.
    /// @param amount Amount to slash from the total staked amount.
    function slash(uint256 amount) external;

    /// @notice Settles the current slashing, allowing the contract to exit slashing mode and resume normal operations.
    function settleSlashing() external;

    /// @notice Sets the cooldown duration for unstaking.
    /// @param cooldownDuration New cooldown duration in seconds.
    function setCooldownDuration(uint256 cooldownDuration) external;

    /// @notice Sets the maximum slashable proportion of the vault balance in basis points.
    /// @param maxSlashableBps New maximum slashable proportion in basis points.
    function setMaxSlashableBps(uint256 maxSlashableBps) external;

    /// @notice Sets the minimum balance that must remain in the vault after a slash.
    /// @param minBalanceAfterSlash New minimum balance after slash.
    function setMinBalanceAfterSlash(uint256 minBalanceAfterSlash) external;
}
