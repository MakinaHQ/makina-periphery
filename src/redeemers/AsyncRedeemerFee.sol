// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import {IMachine} from "@makina-core/interfaces/IMachine.sol";

import {AsyncRedeemer} from "./AsyncRedeemer.sol";
import {IAsyncRedeemerFee} from "../interfaces/IAsyncRedeemerFee.sol";
import {IMachinePeriphery} from "../interfaces/IMachinePeriphery.sol";
import {Errors} from "../libraries/Errors.sol";

contract AsyncRedeemerFee is AsyncRedeemer, IAsyncRedeemerFee {
    using Math for uint256;

    /// @dev Full scale value for fee rates
    uint256 private constant MAX_FEE_RATE = 1e18;

    /// @custom:storage-location erc7201:makina.storage.AsyncRedeemerFee
    struct AsyncRedeemerFeeStorage {
        uint256 _redeemFeeRate;
    }

    // keccak256(abi.encode(uint256(keccak256("makina.storage.AsyncRedeemerFee")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant AsyncRedeemerFeeStorageLocation = 0;

    function _getAsyncRedeemerFeeStorage() private pure returns (AsyncRedeemerFeeStorage storage $) {
        assembly {
            $.slot := AsyncRedeemerFeeStorageLocation
        }
    }

    constructor(address _registry) AsyncRedeemer(_registry) {}

    /// @inheritdoc IMachinePeriphery
    function initialize(bytes calldata data) external virtual override(AsyncRedeemer, IMachinePeriphery) initializer {
        (uint256 _finalizationDelay, uint256 _minRedeemAmount, bool _whitelistStatus, uint256 _redeemFeeRate) =
            abi.decode(data, (uint256, uint256, bool, uint256));

        if (_redeemFeeRate > MAX_FEE_RATE) {
            revert Errors.MaxFeeRateValueExceeded();
        }
        _getAsyncRedeemerFeeStorage()._redeemFeeRate = _redeemFeeRate;

        __AsyncRedeemer_init(_finalizationDelay, _minRedeemAmount, _whitelistStatus);
    }

    /// @inheritdoc IAsyncRedeemerFee
    function redeemFeeRate() external view override returns (uint256) {
        return _getAsyncRedeemerFeeStorage()._redeemFeeRate;
    }

    /// @inheritdoc IAsyncRedeemerFee
    function setRedeemFeeRate(uint256 newRedeemFeeRate) external override onlyRiskManagerTimelock {
        AsyncRedeemerFeeStorage storage $ = _getAsyncRedeemerFeeStorage();

        if (newRedeemFeeRate > MAX_FEE_RATE) {
            revert Errors.MaxFeeRateValueExceeded();
        }

        emit RedeemFeeRateChanged($._redeemFeeRate, newRedeemFeeRate);
        $._redeemFeeRate = newRedeemFeeRate;
    }

    /// @inheritdoc AsyncRedeemer
    function _previewRedeem(uint256 shares) internal view virtual override returns (uint256) {
        return IMachine(machine()).convertToAssets(shares).mulDiv(
            MAX_FEE_RATE - _getAsyncRedeemerFeeStorage()._redeemFeeRate, MAX_FEE_RATE
        );
    }
}
