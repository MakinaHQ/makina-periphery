// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface IMachinePeriphery {
    event MachineSet(address indexed machine);

    /// @notice Initializer of the contract.
    /// @param _data The initialization data, if any.
    function initialize(bytes calldata _data) external;

    /// @notice Address of the associated machine.
    function machine() external view returns (address);

    /// @notice Sets the machine address.
    function setMachine(address _machine) external;
}
