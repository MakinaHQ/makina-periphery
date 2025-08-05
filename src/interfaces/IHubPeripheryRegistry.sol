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
    event StakingModuleBeaconChanged(address indexed oldStakingModuleBeacon, address indexed newStakingModuleBeacon);

    /// @notice Address of the periphery factory.
    function peripheryFactory() external view returns (address);

    /// @notice Implementation ID => Address of the deposit manager beacon
    function machineDepositorBeacon(uint16 implemId) external view returns (address);

    /// @notice Implementation ID => Address of the redeem manager beacon
    function machineRedeemerBeacon(uint16 implemId) external view returns (address);

    /// @notice Implementation ID => Address of the fee manager beacon
    function feeManagerBeacon(uint16 implemId) external view returns (address);

    /// @notice Address of the staking module beacon.
    function stakingModuleBeacon() external view returns (address);

    /// @notice Sets the address of the periphery factory.
    /// @param _peripheryFactory The periphery factory address.
    function setPeripheryFactory(address _peripheryFactory) external;

    /// @notice Sets the beacon address for the deposit manager implementation.
    /// @param implemId The ID of the deposit manager implementation.
    /// @param _machineDepositorBeacon The machine depositor beacon address.
    function setMachineDepositorBeacon(uint16 implemId, address _machineDepositorBeacon) external;

    /// @notice Sets the beacon address for the redeem manager implementation.
    /// @param implemId The ID of the redeem manager implementation.
    /// @param _machineRedeemerBeacon The machine redeemer beacon address.
    function setMachineRedeemerBeacon(uint16 implemId, address _machineRedeemerBeacon) external;

    /// @notice Sets the beacon address for the fee manager implementation.
    /// @param implemId The ID of the fee manager implementation.
    /// @param _feeManagerBeacon The fee manager beacon address.
    function setFeeManagerBeacon(uint16 implemId, address _feeManagerBeacon) external;

    /// @notice Sets the staking module beacon address.
    /// @param _stakingModuleBeacon The staking module beacon address.
    function setStakingModuleBeacon(address _stakingModuleBeacon) external;
}
