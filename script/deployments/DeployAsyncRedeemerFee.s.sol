// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {IHubPeripheryFactory} from "../../src/interfaces/IHubPeripheryFactory.sol";

import {DeployInstance} from "./DeployInstance.s.sol";

/// @notice Builds the `HubPeripheryFactory.createRedeemer` call for a new async redeemer with redeem fee, then
///         broadcasts it or logs it. See `DeployInstance` for modes and env vars.
///
/// Env vars (unless `setParams` and `setImplemId` were called):
///   HUB_PERIPHERY_OUTPUT_FILENAME - hub periphery output file holding the HubPeripheryFactory address
///                                   (under script/deployments/outputs/hub-peripheries/)
///   HUB_PERIPHERY_INPUT_FILENAME  - implementation ids input file (under script/deployments/inputs/implem-ids/)
///   HUB_STRAT_INPUT_FILENAME      - async redeemer fee init params input file
///                                   (under script/deployments/inputs/redeemers/async-redeemer-fees/)
///   HUB_STRAT_OUTPUT_FILENAME     - file to write the async redeemer fee address to
///                                   (under script/deployments/outputs/redeemers/async-redeemer-fees/, broadcast mode only)
///   VIEW_MODE (optional)          - true for view mode, unset or false for broadcast mode
contract DeployAsyncRedeemerFee is DeployInstance {
    function _createCall() internal view override returns (Call memory) {
        uint256 finalizationDelay = vm.parseJsonUint(inputJson, ".finalizationDelay");
        uint256 minRedeemAmount = vm.parseJsonUint(inputJson, ".minRedeemAmount");
        bool whitelistStatus = vm.parseJsonBool(inputJson, ".whitelistStatus");
        bool sanctionsCheckStatus = vm.parseJsonBool(inputJson, ".sanctionsCheckStatus");
        uint256 redeemFeeRate = vm.parseJsonUint(inputJson, ".redeemFeeRate");
        uint256 maxRedeemFeeRate = vm.parseJsonUint(inputJson, ".maxRedeemFeeRate");

        return Call({
            label: "HubPeripheryFactory.createRedeemer",
            target: peripheryFactory,
            data: abi.encodeCall(
                IHubPeripheryFactory.createRedeemer,
                (
                    implemId,
                    abi.encode(
                        finalizationDelay,
                        minRedeemAmount,
                        whitelistStatus,
                        sanctionsCheckStatus,
                        redeemFeeRate,
                        maxRedeemFeeRate
                    )
                )
            )
        });
    }

    function _writeOutput() internal override {
        string memory key = "key-deploy-async-redeemer-fee-output-file";
        vm.writeJson(vm.serializeAddress(key, "AsyncRedeemerFee", deployedInstance), outputPath);
    }

    function _recordDir() internal pure override returns (string memory) {
        return "redeemers/async-redeemer-fees";
    }

    function _loadParamsFromEnv() internal override {
        setImplemId(_implemIdFromRecord(vm.envString("HUB_PERIPHERY_INPUT_FILENAME"), ".asyncRedeemerFeeImplemId"));
        setParams(
            _peripheryFactoryFromRecord(vm.envString("HUB_PERIPHERY_OUTPUT_FILENAME")),
            vm.envString("HUB_STRAT_INPUT_FILENAME"),
            _outputFilenameFromEnv("HUB_STRAT_OUTPUT_FILENAME")
        );
    }
}
