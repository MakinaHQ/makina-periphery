// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IMachineManager} from "src/interfaces/IMachineManager.sol";

/// @dev MockMachineManager contract for testing use only
contract MockMachineManager is IMachineManager {
    function initialize(address, bytes calldata) external override {
        return;
    }

    function machine() external view override returns (address) {
        return address(0);
    }

    function setMachine(address) external override {
        return;
    }
}
