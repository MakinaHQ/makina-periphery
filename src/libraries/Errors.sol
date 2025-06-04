// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Errors as CoreErrors} from "@makina-core/libraries/Errors.sol";

library Errors {
    error InvalidDepositManagerImplemId();
    error InvalidRedeemManagerImplemId();
    error InvalidFeeManagerImplemId();
    error NotDepositManager();
    error NotRedeemManager();
    error NotFeeManager();
}
