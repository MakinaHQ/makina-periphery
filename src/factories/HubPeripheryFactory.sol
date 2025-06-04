// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {AccessManagedUpgradeable} from "@openzeppelin/contracts-upgradeable/access/manager/AccessManagedUpgradeable.sol";
import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";

import {IHubPeripheryFactory} from "../interfaces/IHubPeripheryFactory.sol";
import {IHubPeripheryRegistry} from "../interfaces/IHubPeripheryRegistry.sol";
import {IMachineManager} from "../interfaces/IMachineManager.sol";
import {Errors} from "../libraries/Errors.sol";
import {MakinaPeripheryContext} from "../utils/MakinaPeripheryContext.sol";

contract HubPeripheryFactory is AccessManagedUpgradeable, MakinaPeripheryContext, IHubPeripheryFactory {
    /// @custom:storage-location erc7201:makina.storage.HubPeripheryFactory
    struct HubPeripheryFactoryStorage {
        mapping(address depositManager => bool isDepositManager) _isDepositManager;
        mapping(address redeemManager => bool isRedeemManager) _isRedeemManager;
        mapping(address feeManager => bool isFeeManager) _isFeeManager;
        mapping(address depositManager => uint16 implemId) _depositManagerImplemId;
        mapping(address redeemManager => uint16 implemId) _redeemManagerImplemId;
        mapping(address feeManager => uint16 implemId) _feeManagerImplemId;
    }

    // keccak256(abi.encode(uint256(keccak256("makina.storage.HubPeripheryFactory")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant HubPeripheryFactoryStorageLocation =
        0x6b50a937759edff8a6a5b23fe11eb54a74c1c4f4d159fd3622707013a01a1e00;

    function _getHubPeripheryFactoryStorage() internal pure returns (HubPeripheryFactoryStorage storage $) {
        assembly {
            $.slot := HubPeripheryFactoryStorageLocation
        }
    }

    constructor(address _peripheryRegistry) MakinaPeripheryContext(_peripheryRegistry) {
        _disableInitializers();
    }

    function initialize(address _initialAuthority) external initializer {
        __AccessManaged_init(_initialAuthority);
    }

    /// @inheritdoc IHubPeripheryFactory
    function isDepositManager(address _depositManager) external view override returns (bool) {
        return _getHubPeripheryFactoryStorage()._isDepositManager[_depositManager];
    }

    /// @inheritdoc IHubPeripheryFactory
    function isRedeemManager(address _redeemManager) external view override returns (bool) {
        return _getHubPeripheryFactoryStorage()._isRedeemManager[_redeemManager];
    }

    /// @inheritdoc IHubPeripheryFactory
    function isFeeManager(address _feeManager) external view override returns (bool) {
        return _getHubPeripheryFactoryStorage()._isFeeManager[_feeManager];
    }

    /// @inheritdoc IHubPeripheryFactory
    function depositManagerImplemId(address _depositManager) external view override returns (uint16) {
        HubPeripheryFactoryStorage storage $ = _getHubPeripheryFactoryStorage();
        if (!$._isDepositManager[_depositManager]) {
            revert Errors.NotDepositManager();
        }
        return $._depositManagerImplemId[_depositManager];
    }

    /// @inheritdoc IHubPeripheryFactory
    function redeemManagerImplemId(address _redeemManager) external view override returns (uint16) {
        HubPeripheryFactoryStorage storage $ = _getHubPeripheryFactoryStorage();
        if (!$._isRedeemManager[_redeemManager]) {
            revert Errors.NotRedeemManager();
        }
        return $._redeemManagerImplemId[_redeemManager];
    }

    /// @inheritdoc IHubPeripheryFactory
    function feeManagerImplemId(address _feeManager) external view override returns (uint16) {
        HubPeripheryFactoryStorage storage $ = _getHubPeripheryFactoryStorage();
        if (!$._isFeeManager[_feeManager]) {
            revert Errors.NotFeeManager();
        }
        return $._feeManagerImplemId[_feeManager];
    }

    /// @inheritdoc IHubPeripheryFactory
    function createDepositManager(uint16 _implemId, address _initialAuthority, bytes calldata _initializationData)
        external
        override
        restricted
        returns (address)
    {
        HubPeripheryFactoryStorage storage $ = _getHubPeripheryFactoryStorage();

        address beacon = IHubPeripheryRegistry(peripheryRegistry).depositManagerBeacon(_implemId);
        if (beacon == address(0)) {
            revert Errors.InvalidDepositManagerImplemId();
        }

        address depositManager = address(
            new BeaconProxy(
                beacon, abi.encodeCall(IMachineManager.initialize, (_initialAuthority, _initializationData))
            )
        );

        $._isDepositManager[depositManager] = true;
        $._depositManagerImplemId[depositManager] = _implemId;

        emit DepositManagerCreated(depositManager, _implemId);

        return depositManager;
    }

    /// @inheritdoc IHubPeripheryFactory
    function createRedeemManager(uint16 _implemId, address _initialAuthority, bytes calldata _initializationData)
        external
        override
        restricted
        returns (address)
    {
        HubPeripheryFactoryStorage storage $ = _getHubPeripheryFactoryStorage();

        address beacon = IHubPeripheryRegistry(peripheryRegistry).redeemManagerBeacon(_implemId);
        if (beacon == address(0)) {
            revert Errors.InvalidRedeemManagerImplemId();
        }

        address redeemManager = address(
            new BeaconProxy(
                beacon, abi.encodeCall(IMachineManager.initialize, (_initialAuthority, _initializationData))
            )
        );

        $._isRedeemManager[redeemManager] = true;
        $._redeemManagerImplemId[redeemManager] = _implemId;

        emit RedeemManagerCreated(redeemManager, _implemId);

        return redeemManager;
    }

    /// @inheritdoc IHubPeripheryFactory
    function createFeeManager(uint16 _implemId, address _initialAuthority, bytes calldata _initializationData)
        external
        override
        restricted
        returns (address)
    {
        HubPeripheryFactoryStorage storage $ = _getHubPeripheryFactoryStorage();

        address beacon = IHubPeripheryRegistry(peripheryRegistry).feeManagerBeacon(_implemId);
        if (beacon == address(0)) {
            revert Errors.InvalidFeeManagerImplemId();
        }

        address feeManager = address(
            new BeaconProxy(
                beacon, abi.encodeCall(IMachineManager.initialize, (_initialAuthority, _initializationData))
            )
        );

        $._isFeeManager[feeManager] = true;
        $._feeManagerImplemId[feeManager] = _implemId;

        emit FeeManagerCreated(feeManager, _implemId);

        return feeManager;
    }
}
