// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface IMakinaPeripheryContext {
    /// @notice Address of the periphery registry.
    function peripheryRegistry() external view returns (address);
}
