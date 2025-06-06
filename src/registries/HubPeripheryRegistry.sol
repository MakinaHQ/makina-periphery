// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {AccessManagedUpgradeable} from "@openzeppelin/contracts-upgradeable/access/manager/AccessManagedUpgradeable.sol";

import {IHubPeripheryRegistry} from "../interfaces/IHubPeripheryRegistry.sol";

contract HubPeripheryRegistry is AccessManagedUpgradeable, IHubPeripheryRegistry {
    /// @custom:storage-location erc7201:makina.storage.HubPeripheryRegistry
    struct HubPeripheryRegistryStorage {
        address _peripheryFactory;
        mapping(uint16 implemId => address depositManager) _depositManagers;
        mapping(uint16 implemId => address redeemManager) _redeemManagers;
        mapping(uint16 implemId => address feeManager) _feeManagers;
    }

    // keccak256(abi.encode(uint256(keccak256("makina.storage.HubPeripheryRegistry")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant HubPeripheryRegistryStorageLocation =
        0x60c7a8b9d2c96eeaf12a26c5fbe46f192e4cb2019fd3c31562f5d2011364b000;

    function _getHubPeripheryRegistryStorage() internal pure returns (HubPeripheryRegistryStorage storage $) {
        assembly {
            $.slot := HubPeripheryRegistryStorageLocation
        }
    }

    constructor() {
        _disableInitializers();
    }

    function initialize(address _initialAuthority) external initializer {
        __AccessManaged_init(_initialAuthority);
    }

    /// @inheritdoc IHubPeripheryRegistry
    function peripheryFactory() external view override returns (address) {
        return _getHubPeripheryRegistryStorage()._peripheryFactory;
    }

    /// @inheritdoc IHubPeripheryRegistry
    function depositManagerBeacon(uint16 implemId) external view override returns (address) {
        return _getHubPeripheryRegistryStorage()._depositManagers[implemId];
    }

    /// @inheritdoc IHubPeripheryRegistry
    function redeemManagerBeacon(uint16 implemId) external view override returns (address) {
        return _getHubPeripheryRegistryStorage()._redeemManagers[implemId];
    }

    /// @inheritdoc IHubPeripheryRegistry
    function feeManagerBeacon(uint16 implemId) external view override returns (address) {
        return _getHubPeripheryRegistryStorage()._feeManagers[implemId];
    }

    /// @inheritdoc IHubPeripheryRegistry
    function setPeripheryFactory(address _peripheryFactory) external override restricted {
        HubPeripheryRegistryStorage storage $ = _getHubPeripheryRegistryStorage();
        emit PeripheryFactoryChanged($._peripheryFactory, _peripheryFactory);
        $._peripheryFactory = _peripheryFactory;
    }

    /// @inheritdoc IHubPeripheryRegistry
    function setDepositManagerBeacon(uint16 implemId, address _depositManagerBeacon) external override restricted {
        HubPeripheryRegistryStorage storage $ = _getHubPeripheryRegistryStorage();
        emit DepositManagerBeaconChanged(implemId, $._depositManagers[implemId], _depositManagerBeacon);
        $._depositManagers[implemId] = _depositManagerBeacon;
    }

    /// @inheritdoc IHubPeripheryRegistry
    function setRedeemManagerBeacon(uint16 implemId, address _redeemManagerBeacon) external override restricted {
        HubPeripheryRegistryStorage storage $ = _getHubPeripheryRegistryStorage();
        emit RedeemManagerBeaconChanged(implemId, $._redeemManagers[implemId], _redeemManagerBeacon);
        $._redeemManagers[implemId] = _redeemManagerBeacon;
    }

    /// @inheritdoc IHubPeripheryRegistry
    function setFeeManagerBeacon(uint16 implemId, address _feeManagerBeacon) external override restricted {
        HubPeripheryRegistryStorage storage $ = _getHubPeripheryRegistryStorage();
        emit FeeManagerBeaconChanged(implemId, $._feeManagers[implemId], _feeManagerBeacon);
        $._feeManagers[implemId] = _feeManagerBeacon;
    }
}
