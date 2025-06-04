// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

interface IHubPeripheryFactory {
    event DepositManagerCreated(address indexed depositManager, uint16 indexed implemId);
    event RedeemManagerCreated(address indexed redeemManager, uint16 indexed implemId);
    event FeeManagerCreated(address indexed feeManager, uint16 indexed implemId);

    /// @notice Address => Whether this is a deposit manager deployed by this factory
    function isDepositManager(address depositManager) external view returns (bool);

    /// @notice Address => Whether this is a redeem manager deployed by this factory
    function isRedeemManager(address redeemManager) external view returns (bool);

    /// @notice Address => Whether this is a fee manager deployed by this factory
    function isFeeManager(address feeManager) external view returns (bool);

    /// @notice Deposit manager => Implementation ID
    function depositManagerImplemId(address depositManager) external view returns (uint16);

    /// @notice Redeem manager => Implementation ID
    function redeemManagerImplemId(address redeemManager) external view returns (uint16);

    /// @notice Fee manager => Implementation ID
    function feeManagerImplemId(address feeManager) external view returns (uint16);

    /// @notice Creates a new deposit manager using the specified implementation ID.
    /// @param implemId The ID of the deposit manager implementation to be used.
    /// @param initialAuthority The address of the initial authority.
    /// @param initializationData Additional initialization data.
    /// @return depositManager The address of the newly created deposit manager.
    function createDepositManager(uint16 implemId, address initialAuthority, bytes calldata initializationData)
        external
        returns (address depositManager);

    /// @notice Creates a new redeem manager using the specified implementation ID.
    /// @param implemId The ID of the redeem manager implementation to be used.
    /// @param initialAuthority The address of the initial authority.
    /// @param initializationData Additional initialization data.
    /// @return redeemManager The address of the newly created redeem manager.
    function createRedeemManager(uint16 implemId, address initialAuthority, bytes calldata initializationData)
        external
        returns (address redeemManager);

    /// @notice Creates a new fee manager using the specified implementation ID.
    /// @param implemId The ID of the fee manager implementation to be used.
    /// @param initialAuthority The address of the initial authority.
    /// @param initializationData Additional initialization data.
    /// @return feeManager The address of the newly created fee manager.
    function createFeeManager(uint16 implemId, address initialAuthority, bytes calldata initializationData)
        external
        returns (address feeManager);
}
