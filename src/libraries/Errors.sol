// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Errors as CoreErrors} from "@makina-core/libraries/Errors.sol";

library Errors {
    error AlreadyClaimed();
    error AlreadyFinalized();
    error CooldownOngoing();
    error FinalizationDelayPending();
    error FutureRequest();
    error InvalidMachineDepositorImplemId();
    error InvalidFeeManagerImplemId();
    error InvalidMachineRedeemerImplemId();
    error MachineAlreadySet();
    error MachineNotSet();
    error MaxBpsValueExceeded();
    error MaxSlashableExceeded();
    error NotMachineDepositor();
    error NotEnoughAssets();
    error NotFeeManager();
    error NotFinalized();
    error NotImplemented();
    error NotMachineRedeemer();
    error SlashingSettlementOngoing();
    error ZeroMachineAddress();
    error ZeroRequestId();
}
