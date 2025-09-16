// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {AccessManagedUpgradeable} from "@openzeppelin/contracts-upgradeable/access/manager/AccessManagedUpgradeable.sol";
import {IAccessManaged} from "@openzeppelin/contracts/access/manager/IAccessManaged.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IFeeManager} from "@makina-core/interfaces/IFeeManager.sol";
import {IMachine} from "@makina-core/interfaces/IMachine.sol";

import {IWatermarkFeeManager} from "../interfaces/IWatermarkFeeManager.sol";
import {IMachinePeriphery} from "../interfaces/IMachinePeriphery.sol";
import {ISecurityModuleReference} from "../interfaces/ISecurityModuleReference.sol";
import {Errors, CoreErrors} from "../libraries/Errors.sol";
import {MachinePeriphery} from "../utils/MachinePeriphery.sol";

contract WatermarkFeeManager is MachinePeriphery, AccessManagedUpgradeable, IWatermarkFeeManager {
    using Math for uint256;
    using SafeERC20 for IERC20;

    /// @dev Full scale value in basis points
    uint256 private constant MAX_BPS = 10_000;

    /// @dev Full scale value for fee rates
    uint256 private constant MAX_FEE_RATE = 1e18;

    /// @custom:storage-location erc7201:makina.storage.WatermarkFeeManager
    struct WatermarkFeeManagerStorage {
        uint256 _mgmtFeeRatePerSecond;
        uint256 _smFeeRatePerSecond;
        uint256 _perfFeeRate;
        uint256 _sharePriceWatermark;
        address[] _mgmtFeeReceivers;
        uint256[] _mgmtFeeSplitBps;
        address[] _perfFeeReceivers;
        uint256[] _perfFeeSplitBps;
        address _securityModule;
    }

    // keccak256(abi.encode(uint256(keccak256("makina.storage.WatermarkFeeManager")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant WatermarkFeeManagerStorageLocation =
        0xede173ec12f445c51c989a2ee4f565cf9b40f8a01bd556574a3890308cdf3900;

    function _getWatermarkFeeManagerStorage() private pure returns (WatermarkFeeManagerStorage storage $) {
        assembly {
            $.slot := WatermarkFeeManagerStorageLocation
        }
    }

    constructor(address _registry) MachinePeriphery(_registry) {}

    /// @inheritdoc IMachinePeriphery
    function initialize(bytes calldata data) external override initializer {
        WatermarkFeeManagerStorage storage $ = _getWatermarkFeeManagerStorage();

        WatermarkFeeManagerInitParams memory params = abi.decode(data, (WatermarkFeeManagerInitParams));

        if (
            params.initialMgmtFeeRatePerSecond > MAX_FEE_RATE || params.initialSmFeeRatePerSecond > MAX_FEE_RATE
                || params.initialPerfFeeRate > MAX_FEE_RATE
        ) {
            revert Errors.MaxFeeRateValueExceeded();
        }

        $._mgmtFeeRatePerSecond = params.initialMgmtFeeRatePerSecond;
        $._smFeeRatePerSecond = params.initialSmFeeRatePerSecond;
        $._perfFeeRate = params.initialPerfFeeRate;
        $._mgmtFeeSplitBps = params.initialMgmtFeeSplitBps;
        $._mgmtFeeReceivers = params.initialMgmtFeeReceivers;
        $._perfFeeSplitBps = params.initialPerfFeeSplitBps;
        $._perfFeeReceivers = params.initialPerfFeeReceivers;
    }

    modifier onlyMachine() {
        if (msg.sender != machine()) {
            revert CoreErrors.NotMachine();
        }
        _;
    }

    /// @inheritdoc IAccessManaged
    function authority() public view override returns (address) {
        return IAccessManaged(machine()).authority();
    }

    /// @inheritdoc IWatermarkFeeManager
    function mgmtFeeRatePerSecond() external view override returns (uint256) {
        return _getWatermarkFeeManagerStorage()._mgmtFeeRatePerSecond;
    }

    /// @inheritdoc IWatermarkFeeManager
    function smFeeRatePerSecond() external view override returns (uint256) {
        return _getWatermarkFeeManagerStorage()._smFeeRatePerSecond;
    }

    /// @inheritdoc IWatermarkFeeManager
    function perfFeeRate() external view override returns (uint256) {
        return _getWatermarkFeeManagerStorage()._perfFeeRate;
    }

    /// @inheritdoc IWatermarkFeeManager
    function mgmtFeeReceivers() external view override returns (address[] memory) {
        return _getWatermarkFeeManagerStorage()._mgmtFeeReceivers;
    }

    /// @inheritdoc IWatermarkFeeManager
    function mgmtFeeSplitBps() external view override returns (uint256[] memory) {
        return _getWatermarkFeeManagerStorage()._mgmtFeeSplitBps;
    }

    /// @inheritdoc IWatermarkFeeManager
    function perfFeeReceivers() external view override returns (address[] memory) {
        return _getWatermarkFeeManagerStorage()._perfFeeReceivers;
    }

    /// @inheritdoc IWatermarkFeeManager
    function perfFeeSplitBps() external view override returns (uint256[] memory) {
        return _getWatermarkFeeManagerStorage()._perfFeeSplitBps;
    }

    /// @inheritdoc ISecurityModuleReference
    function securityModule() external view override returns (address) {
        return _getWatermarkFeeManagerStorage()._securityModule;
    }

    /// @inheritdoc IWatermarkFeeManager
    function sharePriceWatermark() external view override returns (uint256) {
        return _getWatermarkFeeManagerStorage()._sharePriceWatermark;
    }

    /// @inheritdoc IFeeManager
    function calculateFixedFee(uint256 currentShareSupply, uint256 elapsedTime)
        external
        view
        override
        returns (uint256)
    {
        WatermarkFeeManagerStorage storage $ = _getWatermarkFeeManagerStorage();

        uint256 twSupply = currentShareSupply * elapsedTime;

        uint256 fixedFeeRatePerSecond =
            $._securityModule != address(0) ? $._mgmtFeeRatePerSecond + $._smFeeRatePerSecond : $._mgmtFeeRatePerSecond;

        return twSupply.mulDiv(fixedFeeRatePerSecond, MAX_FEE_RATE);
    }

    /// @inheritdoc IFeeManager
    function calculatePerformanceFee(uint256 currentShareSupply, uint256, uint256 newSharePrice, uint256)
        external
        override
        onlyMachine
        returns (uint256)
    {
        WatermarkFeeManagerStorage storage $ = _getWatermarkFeeManagerStorage();

        if ($._sharePriceWatermark == 0) {
            $._sharePriceWatermark = newSharePrice;
            return 0;
        }

        if (newSharePrice <= $._sharePriceWatermark) {
            return 0;
        }

        uint256 fee = currentShareSupply.mulDiv(
            (newSharePrice - $._sharePriceWatermark) * $._perfFeeRate, newSharePrice * MAX_FEE_RATE
        );

        $._sharePriceWatermark = newSharePrice;

        return fee;
    }

    /// @inheritdoc IFeeManager
    function distributeFees(uint256 fixedFee, uint256 perfFee) external override onlyMachine {
        WatermarkFeeManagerStorage storage $ = _getWatermarkFeeManagerStorage();

        address _machine = machine();
        address _machineShare = IMachine(_machine).shareToken();

        if (fixedFee != 0) {
            uint256 mgmtFee;
            uint256 smRate = $._smFeeRatePerSecond;
            uint256 mgmtRate = $._mgmtFeeRatePerSecond;

            if ($._securityModule != address(0) && smRate != 0) {
                uint256 smFee = fixedFee.mulDiv(smRate, smRate + mgmtRate);
                mgmtFee = fixedFee - smFee;
                if (smFee != 0) {
                    IERC20(_machineShare).safeTransferFrom(_machine, $._securityModule, smFee);
                }
            } else {
                mgmtFee = fixedFee;
            }

            uint256 len = $._mgmtFeeReceivers.length;
            for (uint256 i; i < len; ++i) {
                uint256 fee = mgmtFee.mulDiv($._mgmtFeeSplitBps[i], MAX_BPS);
                if (fee != 0) {
                    IERC20(_machineShare).safeTransferFrom(_machine, $._mgmtFeeReceivers[i], fee);
                }
            }
        }

        if (perfFee != 0) {
            uint256 len = $._perfFeeReceivers.length;
            for (uint256 i; i < len; ++i) {
                uint256 fee = perfFee.mulDiv($._perfFeeSplitBps[i], MAX_BPS);
                if (fee != 0) {
                    IERC20(_machineShare).safeTransferFrom(_machine, $._perfFeeReceivers[i], fee);
                }
            }
        }
    }

    /// @inheritdoc IWatermarkFeeManager
    function resetSharePriceWatermark(uint256 sharePrice) external override restricted {
        WatermarkFeeManagerStorage storage $ = _getWatermarkFeeManagerStorage();

        if (sharePrice > $._sharePriceWatermark) {
            revert Errors.GreaterThanCurrentWatermark();
        }

        $._sharePriceWatermark = sharePrice;
        emit WatermarkReset(sharePrice);
    }

    /// @inheritdoc IWatermarkFeeManager
    function setMgmtFeeRatePerSecond(uint256 newMgmtFeeRatePerSecond) external override restricted {
        WatermarkFeeManagerStorage storage $ = _getWatermarkFeeManagerStorage();

        if (newMgmtFeeRatePerSecond > MAX_FEE_RATE) {
            revert Errors.MaxFeeRateValueExceeded();
        }

        emit MgmtFeeRatePerSecondChanged($._mgmtFeeRatePerSecond, newMgmtFeeRatePerSecond);
        $._mgmtFeeRatePerSecond = newMgmtFeeRatePerSecond;
    }

    /// @inheritdoc IWatermarkFeeManager
    function setSmFeeRatePerSecond(uint256 newSmFeeRatePerSecond) external override restricted {
        WatermarkFeeManagerStorage storage $ = _getWatermarkFeeManagerStorage();

        if (newSmFeeRatePerSecond > MAX_FEE_RATE) {
            revert Errors.MaxFeeRateValueExceeded();
        }

        emit SmFeeRatePerSecondChanged($._smFeeRatePerSecond, newSmFeeRatePerSecond);
        $._smFeeRatePerSecond = newSmFeeRatePerSecond;
    }

    /// @inheritdoc IWatermarkFeeManager
    function setPerfFeeRate(uint256 newPerfFeeRate) external override restricted {
        WatermarkFeeManagerStorage storage $ = _getWatermarkFeeManagerStorage();

        if (newPerfFeeRate > MAX_FEE_RATE) {
            revert Errors.MaxFeeRateValueExceeded();
        }

        emit PerfFeeRateChanged($._perfFeeRate, newPerfFeeRate);
        $._perfFeeRate = newPerfFeeRate;
    }

    /// @inheritdoc IWatermarkFeeManager
    function setMgmtFeeSplit(address[] calldata newMgmtFeeReceivers, uint256[] calldata newMgmtFeeSplitBps)
        external
        override
        restricted
    {
        WatermarkFeeManagerStorage storage $ = _getWatermarkFeeManagerStorage();

        _checkFeeSplit(newMgmtFeeReceivers, newMgmtFeeSplitBps);

        $._mgmtFeeReceivers = newMgmtFeeReceivers;
        $._mgmtFeeSplitBps = newMgmtFeeSplitBps;
        emit MgmtFeeSplitChanged();
    }

    /// @inheritdoc IWatermarkFeeManager
    function setPerfFeeSplit(address[] calldata newPerfFeeReceivers, uint256[] calldata newPerfFeeSplitBps)
        external
        override
        restricted
    {
        WatermarkFeeManagerStorage storage $ = _getWatermarkFeeManagerStorage();

        _checkFeeSplit(newPerfFeeReceivers, newPerfFeeSplitBps);

        $._perfFeeReceivers = newPerfFeeReceivers;
        $._perfFeeSplitBps = newPerfFeeSplitBps;
        emit PerfFeeSplitChanged();
    }

    /// @inheritdoc ISecurityModuleReference
    function setSecurityModule(address _securityModule) external override onlyFactory {
        WatermarkFeeManagerStorage storage $ = _getWatermarkFeeManagerStorage();

        if ($._securityModule != address(0)) {
            revert Errors.SecurityModuleAlreadySet();
        }
        if (IMachinePeriphery(_securityModule).machine() != machine()) {
            revert Errors.InvalidSecurityModule();
        }

        emit SecurityModuleSet(_securityModule);
        $._securityModule = _securityModule;
    }

    /// @notice Checks that the provided fee split setup is valid.
    function _checkFeeSplit(address[] calldata _feeReceivers, uint256[] calldata _feeSplitBps) internal pure {
        uint256 sLen = _feeSplitBps.length;
        uint256 rLen = _feeReceivers.length;

        if (sLen == 0 || sLen != rLen) {
            revert Errors.InvalidFeeSplit();
        }

        uint256 totalBps;
        for (uint256 i; i < sLen; ++i) {
            totalBps += _feeSplitBps[i];
        }

        if (totalBps != MAX_BPS) {
            revert Errors.InvalidFeeSplit();
        }
    }
}
