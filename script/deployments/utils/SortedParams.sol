// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

abstract contract SortedParams {
    struct FlashloanProvidersSorted {
        address aaveV3AddressProvider;
        address balancerV2Pool;
        address balancerV3Pool;
        address dai;
        address dssFlash;
        address morphoPool;
    }

    struct HubPeripherySorted {
        address asyncRedeemerBeacon;
        address directDepositorBeacon;
        address flashloanAggregator;
        address hubPeripheryFactory;
        address hubPeripheryRegistry;
        address metaMorphoOracleFactory;
        address securityModuleBeacon;
        address watermarkFeeManagerBeacon;
    }

    struct SecurityModuleInitParamsSorted {
        uint256 initialCooldownDuration;
        uint256 initialMaxSlashableBps;
        uint256 initialMinBalanceAfterSlash;
        address machineShare;
    }

    struct WatermarkFeeManagerInitParamsSorted {
        uint256 initialMgmtFeeRatePerSecond;
        address[] initialMgmtFeeReceivers;
        uint256[] initialMgmtFeeSplitBps;
        uint256 initialPerfFeeRate;
        address[] initialPerfFeeReceivers;
        uint256[] initialPerfFeeSplitBps;
        uint256 initialSmFeeRatePerSecond;
    }
}
