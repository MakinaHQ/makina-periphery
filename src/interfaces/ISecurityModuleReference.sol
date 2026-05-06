// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface ISecurityModuleReference {
    /// @notice Security module address.
    function securityModule() external view returns (address);

    /// @notice Sets the security module address.
    /// @param _securityModule The address of the security module.
    function setSecurityModule(address _securityModule) external;
}
