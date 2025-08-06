// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

interface IHubPeripheryRegistry {
    event MachineDepositorBeaconChanged(
        uint16 indexed implemId, address indexed oldMachineDepositorBeacon, address indexed newMachineDepositorBeacon
    );
    event FeeManagerBeaconChanged(
        uint16 indexed implemId, address indexed oldFeeManagerBeacon, address indexed newFeeManagerBeacon
    );
    event PeripheryFactoryChanged(address indexed oldPeripheryFactory, address indexed newPeripheryFactory);
    event MachineRedeemerBeaconChanged(
        uint16 indexed implemId, address indexed oldMachineRedeemerBeacon, address indexed newMachineRedeemerBeacon
    );

    /// @notice Address of the periphery factory.
    function peripheryFactory() external view returns (address);

    /// @notice Implementation ID => Address of the deposit manager beacon
    function machineDepositorBeacon(uint16 implemId) external view returns (address);

    /// @notice Implementation ID => Address of the redeem manager beacon
    function machineRedeemerBeacon(uint16 implemId) external view returns (address);

    /// @notice Implementation ID => Address of the fee manager beacon
    function feeManagerBeacon(uint16 implemId) external view returns (address);

    /// @notice Sets the address of the periphery factory.
    /// @param peripheryFactory The address of the new periphery factory.
    function setPeripheryFactory(address peripheryFactory) external;

    /// @notice Sets the beacon address for the deposit manager implementation.
    /// @param implemId The ID of the deposit manager implementation.
    function setMachineDepositorBeacon(uint16 implemId, address beacon) external;

    /// @notice Sets the beacon address for the redeem manager implementation.
    /// @param implemId The ID of the redeem manager implementation.
    function setMachineRedeemerBeacon(uint16 implemId, address beacon) external;

    /// @notice Sets the beacon address for the fee manager implementation.
    /// @param implemId The ID of the fee manager implementation.
    function setFeeManagerBeacon(uint16 implemId, address beacon) external;
}
