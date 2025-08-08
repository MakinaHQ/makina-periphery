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

    // Fee managers
    uint16 public constant WATERMARK_FEE_MANAGER_IMPLEM_ID = 1;
    uint256 public constant DEFAULT_WATERMARK_FEE_MANAGER_MGMT_FEE_RATE_PER_SECOND = 1e4; // 0.0000000000000001% of supply per second
    uint256 public constant DEFAULT_WATERMARK_FEE_MANAGER_SM_FEE_RATE_PER_SECOND = 1e4; // 0.0000000000000001% of supply per second
    uint256 public constant DEFAULT_WATERMARK_FEE_MANAGER_PERF_FEE_RATE = 1e14; // 0.01% of profit

    // Staking Module
    uint256 public constant DEFAULT_COOLDOWN_DURATION = 7 days;
    uint256 public constant DEFAULT_MAX_SLASHABLE_BPS = 5000; // 50%
    uint256 public constant DEFAULT_MIN_BALANCE_AFTER_SLASH = 1e17; // 0.1 token
}
