// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {Vm} from "forge-std/Vm.sol";

import {IPool} from "@aave/interfaces/IPool.sol";

library FlashLoanHelpers {
    Vm private constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    /// @dev Sets up the caliber contract as a legit caliber in hubCoreFactory's storage.
    function registerCaliber(address hubCoreFactory, address caliber) public {
        // 1. Compute the storage slot for _isCaliber[caliber] in hubCoreFactory's storage
        uint256 isCaliberMappingSlot = 0x092f83b0a9c245bf0116fc4aaf5564ab048ff47d6596f1c61801f18d9dfbea00;
        bytes32 slot = keccak256(abi.encode(address(caliber), bytes32(isCaliberMappingSlot)));

        // 2. Store true (1) at the computed slot
        vm.store(address(hubCoreFactory), slot, bytes32(uint256(1)));
    }

    /// @dev Computes the Aave V3 flashLoan premium for a given amount.
    function getAaveV3FlashloanPremium(address aavePool, uint256 amount) internal view returns (uint256 premium) {
        uint256 premiumPct = IPool(aavePool).FLASHLOAN_PREMIUM_TOTAL();
        uint256 PERCENTAGE_FACTOR = 1e4;
        uint256 HALF_PERCENTAGE_FACTOR = 0.5e4;
        assembly {
            if iszero(or(iszero(premiumPct), iszero(gt(amount, div(sub(not(0), HALF_PERCENTAGE_FACTOR), premiumPct)))))
            {
                revert(0, 0)
            }
            premium := div(add(mul(amount, premiumPct), HALF_PERCENTAGE_FACTOR), PERCENTAGE_FACTOR)
        }
    }
}
