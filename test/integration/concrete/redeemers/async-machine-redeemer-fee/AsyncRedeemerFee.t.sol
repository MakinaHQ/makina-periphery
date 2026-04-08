// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {MachineShare} from "@makina-core/machine/MachineShare.sol";

import {IAsyncRedeemer} from "src/interfaces/IAsyncRedeemer.sol";
import {IAsyncRedeemerFee} from "src/interfaces/IAsyncRedeemerFee.sol";

import {AsyncRedeemer_Shared_Integration_Concrete_Test} from "../async-machine-redeemer/AsyncRedeemerShared.t.sol";
import {RequestRedeem_Integration_Concrete_Test} from "../async-machine-redeemer/request-redeem/requestRedeem.t.sol";
import {PreviewFinalizeRequests_Integration_Concrete_Test} from
    "../async-machine-redeemer/preview-finalize-requests/previewFinalizeRequests.t.sol";
import {FinalizeRequests_Integration_Concrete_Test} from
    "../async-machine-redeemer/finalize-requests/finalizeRequests.t.sol";
import {ClaimAssets_Integration_Concrete_Test} from "../async-machine-redeemer/claim-assets/claimAssets.t.sol";

abstract contract AsyncRedeemerFee_Integration_Concrete_Test is AsyncRedeemer_Shared_Integration_Concrete_Test {
    function setUp() public virtual override {
        AsyncRedeemer_Shared_Integration_Concrete_Test.setUp();

        vm.prank(dao);
        asyncRedeemer = IAsyncRedeemer(
            hubPeripheryFactory.createRedeemer(
                ASYNC_REDEEMER_FEE_IMPLEM_ID,
                abi.encode(
                    DEFAULT_FINALIZATION_DELAY,
                    DEFAULT_MIN_REDEEM_AMOUNT,
                    DEFAULT_INITIAL_WHITELIST_STATUS,
                    DEFAULT_REDEEM_FEE_RATE,
                    DEFAULT_MAX_REDEEM_FEE_RATE
                )
            )
        );

        depositorAddr = makeAddr("depositor");

        (machine,) = _deployMachine(address(accountingToken), depositorAddr, address(asyncRedeemer), address(0));
        machineShare = MachineShare(machine.shareToken());

        skip(1);
    }

    function _previewRedeem(uint256 shares) internal view override returns (uint256) {
        return
            machine.convertToAssets(shares) * (1e18 - IAsyncRedeemerFee(address(asyncRedeemer)).redeemFeeRate()) / 1e18;
    }
}

contract AsyncRedeemerFee_RequestRedeem_Integration_Concrete_Test is
    AsyncRedeemerFee_Integration_Concrete_Test,
    RequestRedeem_Integration_Concrete_Test
{
    function setUp()
        public
        override(AsyncRedeemerFee_Integration_Concrete_Test, AsyncRedeemer_Shared_Integration_Concrete_Test)
    {
        AsyncRedeemerFee_Integration_Concrete_Test.setUp();
    }
}

contract AsyncRedeemer_PreviewFinalizeRequest_Integration_Concrete_Test is
    AsyncRedeemerFee_Integration_Concrete_Test,
    PreviewFinalizeRequests_Integration_Concrete_Test
{
    function setUp()
        public
        override(AsyncRedeemerFee_Integration_Concrete_Test, PreviewFinalizeRequests_Integration_Concrete_Test)
    {
        AsyncRedeemerFee_Integration_Concrete_Test.setUp();
        PreviewFinalizeRequests_Integration_Concrete_Test.setUp();
    }
}

contract AsyncRedeemer_FinalizeRequest_Integration_Concrete_Test is
    AsyncRedeemerFee_Integration_Concrete_Test,
    FinalizeRequests_Integration_Concrete_Test
{
    function setUp()
        public
        override(AsyncRedeemerFee_Integration_Concrete_Test, FinalizeRequests_Integration_Concrete_Test)
    {
        AsyncRedeemerFee_Integration_Concrete_Test.setUp();
        FinalizeRequests_Integration_Concrete_Test.setUp();
    }
}

contract AsyncRedeemer_ClaimAssets_Integration_Concrete_Test is
    AsyncRedeemerFee_Integration_Concrete_Test,
    ClaimAssets_Integration_Concrete_Test
{
    function setUp()
        public
        override(AsyncRedeemerFee_Integration_Concrete_Test, ClaimAssets_Integration_Concrete_Test)
    {
        AsyncRedeemerFee_Integration_Concrete_Test.setUp();
        ClaimAssets_Integration_Concrete_Test.setUp();
    }
}
