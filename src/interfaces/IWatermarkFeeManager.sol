// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IFeeManager} from "@makina-core/interfaces/IFeeManager.sol";

import {IMachinePeriphery} from "./IMachinePeriphery.sol";
import {ISecurityModuleReference} from "./ISecurityModuleReference.sol";

interface IWatermarkFeeManager is IFeeManager, ISecurityModuleReference, IMachinePeriphery {
    event MgmtFeeSplitChanged();
    event MgmtFeeRatePerSecondChanged(uint256 oldRate, uint256 newRate);
    event PerfFeeRateChanged(uint256 oldRate, uint256 newRate);
    event PerfFeeSplitChanged();
    event SmFeeRatePerSecondChanged(uint256 oldRate, uint256 newRate);
    event SecurityModuleSet(address indexed securityModule);
    event WatermarkReset(uint256 indexed newWatermark);

    /// @notice Initialization parameters.
    /// @param initialMgmtFeeRatePerSecond Management fee rate per second, in 18 decimals precision.
    /// @param initialSmFeeRatePerSecond Security module fee rate per second, in 18 decimals precision.
    /// @param initialPerfFeeRate Performance fee rate on profit, in 18 decimals precision.
    /// @param initialMgmtFeeSplitBps Fixed fee split between receivers in basis points. Values must sum to 10_000.
    /// @param initialMgmtFeeReceivers Fixed fee receivers.
    /// @param initialPerfFeeSplitBps Performance fee split between receivers in basis points. Values must sum to 10_000.
    /// @param initialPerfFeeReceivers Performance fee receivers.
    struct WatermarkFeeManagerInitParams {
        uint256 initialMgmtFeeRatePerSecond;
        uint256 initialSmFeeRatePerSecond;
        uint256 initialPerfFeeRate;
        uint256[] initialMgmtFeeSplitBps;
        address[] initialMgmtFeeReceivers;
        uint256[] initialPerfFeeSplitBps;
        address[] initialPerfFeeReceivers;
    }

    /// @notice Management fee rate per second, 1e18 = 100%.
    function mgmtFeeRatePerSecond() external view returns (uint256);

    /// @notice Security module fee rate per second, 1e18 = 100%.
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

    /// @notice Sets the security module fee rate per second.
    /// @param newSmFeeRatePerSecond The new security module fee rate per second. 1e18 = 100%.
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
