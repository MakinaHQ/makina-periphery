// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

interface IHubPeripheryFactory {
    event MachineDepositorCreated(address indexed machineDepositor, uint16 indexed implemId);
    event MachineRedeemerCreated(address indexed machineRedeemer, uint16 indexed implemId);
    event FeeManagerCreated(address indexed feeManager, uint16 indexed implemId);

    /// @notice Address => Whether this is a deposit manager deployed by this factory
    function isMachineDepositor(address machineDepositor) external view returns (bool);

    /// @notice Address => Whether this is a redeem manager deployed by this factory
    function isMachineRedeemer(address machineRedeemer) external view returns (bool);

    /// @notice Address => Whether this is a fee manager deployed by this factory
    function isFeeManager(address feeManager) external view returns (bool);

    /// @notice Deposit manager => Implementation ID
    function machineDepositorImplemId(address machineDepositor) external view returns (uint16);

    /// @notice Redeem manager => Implementation ID
    function machineRedeemerImplemId(address machineRedeemer) external view returns (uint16);

    /// @notice Fee manager => Implementation ID
    function feeManagerImplemId(address feeManager) external view returns (uint16);

    /// @notice Creates a new deposit manager using the specified implementation ID.
    /// @param implemId The ID of the deposit manager implementation to be used.
    /// @param initializationData Additional initialization data.
    /// @return machineDepositor The address of the newly created deposit manager.
    function createMachineDepositor(uint16 implemId, bytes calldata initializationData)
        external
        returns (address machineDepositor);

    /// @notice Creates a new redeem manager using the specified implementation ID.
    /// @param implemId The ID of the redeem manager implementation to be used.
    /// @param initializationData Additional initialization data.
    /// @return machineRedeemer The address of the newly created redeem manager.
    function createMachineRedeemer(uint16 implemId, bytes calldata initializationData)
        external
        returns (address machineRedeemer);

    /// @notice Creates a new fee manager using the specified implementation ID.
    /// @param implemId The ID of the fee manager implementation to be used.
    /// @param initializationData Additional initialization data.
    /// @return feeManager The address of the newly created fee manager.
    function createFeeManager(uint16 implemId, bytes calldata initializationData)
        external
        returns (address feeManager);
}
