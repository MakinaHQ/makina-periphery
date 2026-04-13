// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {Vm} from "forge-std/Vm.sol";

import {ISecurityModule} from "../../src/interfaces/ISecurityModule.sol";
import {IWatermarkFeeManager} from "../../src/interfaces/IWatermarkFeeManager.sol";

abstract contract JsonParser {
    struct FlashloanProviders {
        address balancerV2Pool;
        address balancerV3Pool;
        address morphoPool;
        address dssFlash;
        address aaveV3AddressProvider;
        address dai;
    }

    Vm private constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    function parseFlashloanProviders(string memory inputJson, string memory key)
        internal
        view
        returns (FlashloanProviders memory)
    {
        return FlashloanProviders({
            balancerV2Pool: vm.parseJsonAddress(inputJson, string.concat(key, ".balancerV2Pool")),
            balancerV3Pool: vm.parseJsonAddress(inputJson, string.concat(key, ".balancerV3Pool")),
            morphoPool: vm.parseJsonAddress(inputJson, string.concat(key, ".morphoPool")),
            dssFlash: vm.parseJsonAddress(inputJson, string.concat(key, ".dssFlash")),
            aaveV3AddressProvider: vm.parseJsonAddress(inputJson, string.concat(key, ".aaveV3AddressProvider")),
            dai: vm.parseJsonAddress(inputJson, string.concat(key, ".dai"))
        });
    }

    function parseSecurityModuleInitParams(string memory inputJson)
        internal
        view
        returns (ISecurityModule.SecurityModuleInitParams memory)
    {
        return ISecurityModule.SecurityModuleInitParams({
            machineShare: vm.parseJsonAddress(inputJson, string.concat(".machineShare")),
            initialCooldownDuration: vm.parseJsonUint(inputJson, string.concat(".initialCooldownDuration")),
            initialMaxSlashableBps: vm.parseJsonUint(inputJson, string.concat(".initialMaxSlashableBps")),
            initialMinBalanceAfterSlash: vm.parseJsonUint(inputJson, string.concat(".initialMinBalanceAfterSlash"))
        });
    }

    function parseWatermarkFeeManagerInitParams(string memory inputJson, string memory key)
        internal
        view
        returns (IWatermarkFeeManager.WatermarkFeeManagerInitParams memory)
    {
        return IWatermarkFeeManager.WatermarkFeeManagerInitParams({
            initialMgmtFeeRatePerSecond: vm.parseJsonUint(
                inputJson, string.concat(key, ".initialMgmtFeeRatePerSecond")
            ),
            initialSmFeeRatePerSecond: vm.parseJsonUint(inputJson, string.concat(key, ".initialSmFeeRatePerSecond")),
            initialPerfFeeRate: vm.parseJsonUint(inputJson, string.concat(key, ".initialPerfFeeRate")),
            initialMgmtFeeSplitBps: vm.parseJsonUintArray(inputJson, string.concat(key, ".initialMgmtFeeSplitBps")),
            initialMgmtFeeReceivers: vm.parseJsonAddressArray(
                inputJson, string.concat(key, ".initialMgmtFeeReceivers")
            ),
            initialPerfFeeSplitBps: vm.parseJsonUintArray(inputJson, string.concat(key, ".initialPerfFeeSplitBps")),
            initialPerfFeeReceivers: vm.parseJsonAddressArray(inputJson, string.concat(key, ".initialPerfFeeReceivers"))
        });
    }
}
