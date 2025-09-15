// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {IMakinaPeripheryContext} from "../interfaces/IMakinaPeripheryContext.sol";

abstract contract MakinaPeripheryContext is IMakinaPeripheryContext {
    /// @inheritdoc IMakinaPeripheryContext
    address public immutable override peripheryRegistry;

    constructor(address _peripheryRegistry) {
        peripheryRegistry = _peripheryRegistry;
    }
}
