// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {IMachinePeriphery} from "src/interfaces/IMachinePeriphery.sol";

/// @dev MockMachinePeriphery contract for testing use only
contract MockMachinePeriphery is IMachinePeriphery {
    address public machine;

    function initialize(bytes calldata) external pure override {
        return;
    }

    function setMachine(address _machine) external override {
        machine = _machine;
    }
}
