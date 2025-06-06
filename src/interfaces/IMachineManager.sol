/// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

interface IMachineManager {
    /// @notice Initializes the machine manager with the initial authority.
    /// @param _initialAuthority The address of the initial authority.
    /// @param _data Additional initialization data, if any.
    function initialize(address _initialAuthority, bytes calldata _data) external;

    /// @notice Address of the associated machine.
    function machine() external view returns (address);

    /// @notice Sets the machine address.
    function setMachine(address _machine) external;
}
