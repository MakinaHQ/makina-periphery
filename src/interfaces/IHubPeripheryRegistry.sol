// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

interface IHubPeripheryRegistry {
    event DepositorBeaconChanged(
        uint16 indexed implemId, address indexed oldDepositorBeacon, address indexed newDepositorBeacon
    );
    event FeeManagerBeaconChanged(
        uint16 indexed implemId, address indexed oldFeeManagerBeacon, address indexed newFeeManagerBeacon
    );
    event PeripheryFactoryChanged(address indexed oldPeripheryFactory, address indexed newPeripheryFactory);
    event RedeemerBeaconChanged(
        uint16 indexed implemId, address indexed oldRedeemerBeacon, address indexed newRedeemerBeacon
    );
    event StakingModuleBeaconChanged(address indexed oldStakingModuleBeacon, address indexed newStakingModuleBeacon);

    /// @notice Address of the periphery factory.
    function peripheryFactory() external view returns (address);

    /// @notice Implementation ID => Address of the depositor beacon
    function depositorBeacon(uint16 implemId) external view returns (address);

    /// @notice Implementation ID => Address of the redeemer beacon
    function redeemerBeacon(uint16 implemId) external view returns (address);

    /// @notice Implementation ID => Address of the fee manager beacon
    function feeManagerBeacon(uint16 implemId) external view returns (address);

    /// @notice Address of the staking module beacon.
    function stakingModuleBeacon() external view returns (address);

    /// @notice Sets the address of the periphery factory.
    /// @param _peripheryFactory The periphery factory address.
    function setPeripheryFactory(address _peripheryFactory) external;

    /// @notice Sets the beacon address for the depositor implementation.
    /// @param implemId The ID of the machine depositor implementation.
    /// @param _depositorBeacon The machine depositor beacon address.
    function setDepositorBeacon(uint16 implemId, address _depositorBeacon) external;

    /// @notice Sets the beacon address for the redeemer implementation.
    /// @param implemId The ID of the redeemer implementation.
    /// @param _redeemerBeacon The machine redeemer beacon address.
    function setRedeemerBeacon(uint16 implemId, address _redeemerBeacon) external;

    /// @notice Sets the beacon address for the fee manager implementation.
    /// @param implemId The ID of the fee manager implementation.
    /// @param _feeManagerBeacon The fee manager beacon address.
    function setFeeManagerBeacon(uint16 implemId, address _feeManagerBeacon) external;

    /// @notice Sets the staking module beacon address.
    /// @param _stakingModuleBeacon The staking module beacon address.
    function setStakingModuleBeacon(address _stakingModuleBeacon) external;
}
