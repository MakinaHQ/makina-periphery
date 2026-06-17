// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";

import {IDirectDepositor} from "../interfaces/IDirectDepositor.sol";
import {IDirectDepositorPausable} from "../interfaces/IDirectDepositorPausable.sol";
import {DirectDepositor} from "./DirectDepositor.sol";

contract DirectDepositorPausable is DirectDepositor, Pausable, IDirectDepositorPausable {
    constructor(address _registry) DirectDepositor(_registry) {}

    /// @inheritdoc IDirectDepositor
    function deposit(uint256 assets, address receiver, uint256 minShares, bytes32 referralKey)
        public
        virtual
        override(DirectDepositor, IDirectDepositor)
        whenNotPaused
        returns (uint256)
    {
        return super.deposit(assets, receiver, minShares, referralKey);
    }

    /// @inheritdoc IDirectDepositorPausable
    function togglePause() external override onlyRiskManager {
        paused() ? _unpause() : _pause();
    }
}
