// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface IMachineShareOracleFactory {
    event MachineShareOracleCreated(address indexed oracle);
    event MachineShareOracleBeaconChanged(address indexed oldBeacon, address indexed newBeacon);

    /// @notice Address of the machine share oracle beacon.
    function machineShareOracleBeacon() external view returns (address);

    /// @notice Address => Whether this is an oracle deployed by this factory.
    /// @param oracle The oracle address to check.
    function isMachineShareOracle(address oracle) external view returns (bool);

    /// @notice Creates an oracle for the given machine share.
    /// @param shareOwner The current owner contract of the share (machine or pre-deposit vault).
    /// @param decimals Decimals to use for the oracle price.
    function createMachineShareOracle(address shareOwner, uint8 decimals) external returns (address);

    /// @notice Sets the machine share oracle beacon address.
    /// @param _machineShareOracleBeacon The address of the machine share oracle beacon.
    function setMachineShareOracleBeacon(address _machineShareOracleBeacon) external;
}
