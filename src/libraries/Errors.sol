// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Errors as CoreErrors} from "@makina-core/libraries/Errors.sol";

library Errors {
    error AlreadyClaimed();
    error AlreadyFinalized();
    error CooldownOngoing();
    error FinalizationDelayPending();
    error FutureRequest();
    error GreaterThanCurrentWatermark();
    error InvalidFeeSplit();
    error InvalidDepositorImplemId();
    error InvalidFeeManagerImplemId();
    error InvalidRedeemerImplemId();
    error InvalidStakingModule();
    error MachineAlreadySet();
    error MachineNotSet();
    error MaxBpsValueExceeded();
    error MaxFeeRateValueExceeded();
    error MaxSlashableExceeded();
    error NotEnoughAssets();
    error NotFeeManager();
    error NotFinalized();
    error NotImplemented();
    error NotDepositor();
    error NotMachinePeriphery();
    error NotRedeemer();
    error NotStakingModule();
    error SlashingSettlementOngoing();
    error StakingModuleAlreadySet();
    error ZeroMachineAddress();
    error ZeroRequestId();
}
