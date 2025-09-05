// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/// @title IMetaMorphoFactory
/// @notice Interface of MetaMorpho's factory.
interface IMetaMorphoFactory {
    /// @notice Whether a MetaMorpho vault was created with the factory.
    function isMetaMorpho(address target) external view returns (bool);
}
