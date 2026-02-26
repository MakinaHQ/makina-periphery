// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

abstract contract Constants {
    /*//////////////////////////////////////////////////////////////////////////
                                IMPLEMENTATION IDS
    //////////////////////////////////////////////////////////////////////////*/

    uint16 internal constant DUMMY_MANAGER_IMPLEM_ID = 0;

    // Depositors
    uint16 internal constant DIRECT_DEPOSITOR_IMPLEM_ID = 1001;

    // Redeemers
    uint16 internal constant ASYNC_REDEEMER_IMPLEM_ID = 2001;
    uint16 internal constant ASYNC_REDEEMER_FEE_IMPLEM_ID = 2002;

    // Fee managers
    uint16 internal constant WATERMARK_FEE_MANAGER_IMPLEM_ID = 3001;

    /*//////////////////////////////////////////////////////////////////////////
                                        MISC
    //////////////////////////////////////////////////////////////////////////*/

    // Whitelist
    bool internal constant DEFAULT_INITIAL_WHITELIST_STATUS = false;

    // Redeemers
    uint256 internal constant DEFAULT_FINALIZATION_DELAY = 1 hours;
    uint256 internal constant DEFAULT_MIN_REDEEM_AMOUNT = 100;
    uint256 internal constant DEFAULT_REDEEM_FEE_RATE = 1e15; // 0.1% fee

    // Fee managers
    uint256 internal constant DEFAULT_WATERMARK_FEE_MANAGER_MGMT_FEE_RATE_PER_SECOND = 1e4; // 0.0000000000000001% of supply per second
    uint256 internal constant DEFAULT_WATERMARK_FEE_MANAGER_SM_FEE_RATE_PER_SECOND = 1e4; // 0.0000000000000001% of supply per second
    uint256 internal constant DEFAULT_WATERMARK_FEE_MANAGER_PERF_FEE_RATE = 1e14; // 0.01% of profit

    // Security Module
    uint256 internal constant DEFAULT_COOLDOWN_DURATION = 7 days;
    uint256 internal constant DEFAULT_MAX_SLASHABLE_BPS = 5000; // 50%
    uint256 internal constant DEFAULT_MIN_BALANCE_AFTER_SLASH = 1e17; // 0.1 token
}
