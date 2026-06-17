// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IDirectDepositor} from "./IDirectDepositor.sol";

interface IDirectDepositorPausable is IDirectDepositor {
    /// @notice Toggles the paused state of the depositor.
    /// @dev When paused, deposits are blocked. Can only be called by the risk manager.
    function togglePause() external;
}
