// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";

import {Errors} from "src/libraries/Errors.sol";
import {IMachinePeriphery} from "src/interfaces/IMachinePeriphery.sol";

import {AsyncRedeemerFee_Integration_Concrete_Test} from "../AsyncRedeemerFee.t.sol";

contract Initialize_Integration_Concrete_Test is AsyncRedeemerFee_Integration_Concrete_Test {
    function test_RevertWhen_ProvidedMaxFeeRateValueExceeded() public {
        bytes memory data =
            abi.encode(DEFAULT_FINALIZATION_DELAY, DEFAULT_MIN_REDEEM_AMOUNT, DEFAULT_INITIAL_WHITELIST_STATUS, 2, 1);

        vm.expectRevert(Errors.MaxFeeRateValueExceeded.selector);
        new BeaconProxy(address(asyncRedeemerFeeBeacon), abi.encodeCall(IMachinePeriphery.initialize, (data)));

        data = abi.encode(
            DEFAULT_FINALIZATION_DELAY, DEFAULT_MIN_REDEEM_AMOUNT, DEFAULT_INITIAL_WHITELIST_STATUS, 1, 1e18 + 1
        );

        vm.expectRevert(Errors.MaxFeeRateValueExceeded.selector);
        new BeaconProxy(address(asyncRedeemerFeeBeacon), abi.encodeCall(IMachinePeriphery.initialize, (data)));
    }
}
