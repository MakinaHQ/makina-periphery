/// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {IFeeManager} from "@makina-core/interfaces/IFeeManager.sol";

import {IMachinePeriphery} from "./IMachinePeriphery.sol";
import {IStakingModuleReference} from "./IStakingModuleReference.sol";

interface IWatermarkFeeManager is IFeeManager, IStakingModuleReference, IMachinePeriphery {
    event MgmtFeeSplitChanged();
    event MgmtFeeRatePerSecondChanged(uint256 oldRate, uint256 newRate);
    event PerfFeeRateChanged(uint256 oldRate, uint256 newRate);
    event PerfFeeSplitChanged();
    event SmFeeRatePerSecondChanged(uint256 oldRate, uint256 newRate);
    event StakingModuleSet(address indexed stakingModule);
    event WatermarkReset(uint256 indexed newWatermark);

    /// @notice Initialization parameters.
    /// @param _initialMgmtFeeRate Management fee rate in 18 decimals precision.
    /// @param _initialSmFeeRate Staking module fee rate in 18 decimals precision.
    /// @param _initialPerfFeeRate Performance fee rate in 18 decimals precision.
    /// @param _initialMgmtFeeSplitBps Fixed fee split between receivers in basis points. Values must sum to 10_000.
    /// @param _initialMgmtFeeReceivers Fixed fee receivers.
    /// @param _initialPerfFeeSplitBps Performance fee split between receivers in basis points. Values must sum to 10_000.
    /// @param _initialPerfFeeReceivers Performance fee receivers.
    struct WatermarkFeeManagerInitParams {
        uint256 _initialMgmtFeeRatePerSecond;
        uint256 _initialSmFeeRatePerSecond;
        uint256 _initialPerfFeeRate;
        uint256[] _initialMgmtFeeSplitBps;
        address[] _initialMgmtFeeReceivers;
        uint256[] _initialPerfFeeSplitBps;
        address[] _initialPerfFeeReceivers;
    }

    /// @notice Management fee rate per second, 1e18 = 100%.
    function mgmtFeeRatePerSecond() external view returns (uint256);

    /// @notice Staking module fee rate per second, 1e18 = 100%.
    function smFeeRatePerSecond() external view returns (uint256);

    /// @notice Performance fee rate on profit, 1e18 = 100%.
    function perfFeeRate() external view returns (uint256);

    /// @notice Fixed fee receivers.
    function mgmtFeeReceivers() external view returns (address[] memory);

    /// @notice Fixed fee split between receivers in basis points. Values must sum to 10_000.
    function mgmtFeeSplitBps() external view returns (uint256[] memory);

    /// @notice Performance fee receivers.
    function perfFeeReceivers() external view returns (address[] memory);

    /// @notice Performance fee split between receivers in basis points. Values must sum to 10_000.
    function perfFeeSplitBps() external view returns (uint256[] memory);

    /// @notice Current share price high watermark for the associated Machine.
    function sharePriceWatermark() external view returns (uint256);

    /// @notice Resets the share price high watermark.
    function resetSharePriceWatermark(uint256 sharePrice) external;

    /// @notice Sets the management fee rate per second.
    /// @param newMgmtFeeRatePerSecond The new management fee rate per second. 1e18 = 100%.
    function setMgmtFeeRatePerSecond(uint256 newMgmtFeeRatePerSecond) external;

    /// @notice Sets the staking module fee rate per second.
    /// @param newSmFeeRatePerSecond The new staking module fee rate per second. 1e18 = 100%.
    function setSmFeeRatePerSecond(uint256 newSmFeeRatePerSecond) external;

    /// @notice Sets the performance fee rate.
    /// @param newPerfFeeRate The new performance fee rate on profit. 1e18 = 100%.
    function setPerfFeeRate(uint256 newPerfFeeRate) external;

    /// @notice Sets the fixed fee split and receivers.
    /// @param newMgmtFeeReceivers The new fixed fee receivers.
    /// @param newMgmtFeeSplitBps The new fixed fee split between receivers in basis points. Values must sum to 10_000.
    function setMgmtFeeSplit(address[] calldata newMgmtFeeReceivers, uint256[] calldata newMgmtFeeSplitBps) external;

    /// @notice Sets the performance fee split and receivers.
    /// @param newPerfFeeReceivers The new performance fee receivers.
    /// @param newPerfFeeSplitBps The new performance fee split between receivers in basis points. Values must sum to 10_000.
    function setPerfFeeSplit(address[] calldata newPerfFeeReceivers, uint256[] calldata newPerfFeeSplitBps) external;
}
