/// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

interface IStakingModuleReference {
    /// @notice Staking module address.
    function stakingModule() external view returns (address);

    /// @notice Sets the staking module address.
    /// @param stakingModule The address of the staking module.
    function setStakingModule(address stakingModule) external;
}
