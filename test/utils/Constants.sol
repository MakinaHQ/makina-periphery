// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.28;

abstract contract Constants {
    uint16 public constant DUMMY_MANAGER_IMPLEM_ID = 0;

    // Deposit managers
    uint16 public constant OPEN_DEPOSIT_MANAGER_IMPLEM_ID = 1;
    uint16 public constant WHITELISTED_DEPOSIT_MANAGER_IMPLEM_ID = 2;

    // Redeem managers
    uint16 public constant ASYNC_REDEEM_MANAGER_IMPLEM_ID = 1;
    uint16 public constant WHITELISTED_ASYNC_REDEEM_MANAGER_IMPLEM_ID = 2;
    uint256 public constant DEFAULT_FINALIZATION_DELAY = 1 hours;
}
