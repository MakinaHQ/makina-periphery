// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ISecurityModule} from "../interfaces/ISecurityModule.sol";

interface IHubPeripheryFactory {
    event DepositorCreated(address indexed depositor, uint16 indexed implemId);
    event RedeemerCreated(address indexed redeemer, uint16 indexed implemId);
    event FeeManagerCreated(address indexed feeManager, uint16 indexed implemId);
    event SecurityModuleCreated(address indexed securityModule);

    /// @notice Address => Whether this is a depositor deployed by this factory
    function isDepositor(address depositor) external view returns (bool);

    /// @notice Address => Whether this is a redeemer deployed by this factory
    function isRedeemer(address redeemer) external view returns (bool);

    /// @notice Address => Whether this is a fee manager deployed by this factory
    function isFeeManager(address feeManager) external view returns (bool);

    /// @notice Address => Whether this is a security module deployed by this factory
    function isSecurityModule(address securityModule) external view returns (bool);

    /// @notice Depositor => Implementation ID
    function depositorImplemId(address depositor) external view returns (uint16);

    /// @notice Redeemer => Implementation ID
    function redeemerImplemId(address redeemer) external view returns (uint16);

    /// @notice Fee manager => Implementation ID
    function feeManagerImplemId(address feeManager) external view returns (uint16);

    /// @notice Sets the machine address in the machine periphery contract.
    /// @param machinePeriphery The address of the machine periphery contract.
    /// @param machine The address of the machine to be set.
    function setMachine(address machinePeriphery, address machine) external;

    /// @notice Sets the security module address in the fee manager contract.
    /// @param feeManager The address of the fee manager contract.
    /// @param securityModule The address of the security module to be set.
    function setSecurityModule(address feeManager, address securityModule) external;

    /// @notice Creates a new machine depositor using the specified implementation ID.
    /// @param implemId The ID of the depositor implementation to be used.
    /// @param initializationData Additional initialization data.
    /// @return depositor The address of the newly created depositor.
    function createDepositor(uint16 implemId, bytes calldata initializationData) external returns (address depositor);

    /// @notice Creates a new machine redeemer using the specified implementation ID.
    /// @param implemId The ID of the redeemer implementation to be used.
    /// @param initializationData Additional initialization data.
    /// @return redeemer The address of the newly created redeemer.
    function createRedeemer(uint16 implemId, bytes calldata initializationData) external returns (address redeemer);

    /// @notice Creates a new machine fee manager using the specified implementation ID.
    /// @param implemId The ID of the fee manager implementation to be used.
    /// @param initializationData Additional initialization data.
    /// @return feeManager The address of the newly created fee manager.
    function createFeeManager(uint16 implemId, bytes calldata initializationData)
        external
        returns (address feeManager);

    /// @notice Creates a new security module.
    /// @param smParams The security module initialization parameters.
    /// @return securityModule The address of the newly created security module.
    function createSecurityModule(ISecurityModule.SecurityModuleInitParams calldata smParams)
        external
        returns (address securityModule);
}
