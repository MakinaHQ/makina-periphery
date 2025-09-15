// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IMachinePeriphery} from "./IMachinePeriphery.sol";

interface IDirectDepositor is IMachinePeriphery {
    function deposit(uint256 assets, address receiver, uint256 minShares) external returns (uint256);
}
