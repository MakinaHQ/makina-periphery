// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IMachinePeriphery} from "src/interfaces/IMachinePeriphery.sol";

/// @dev MockMachinePeriphery contract for testing use only
contract MockMachinePeriphery is IMachinePeriphery {
    function initialize(bytes calldata) external pure override {
        return;
    }

    function machine() external pure override returns (address) {
        return address(0);
    }

    function setMachine(address) external pure override {
        return;
    }
}
