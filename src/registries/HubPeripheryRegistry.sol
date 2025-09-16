// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {AccessManagedUpgradeable} from "@openzeppelin/contracts-upgradeable/access/manager/AccessManagedUpgradeable.sol";

import {IHubPeripheryRegistry} from "../interfaces/IHubPeripheryRegistry.sol";

contract HubPeripheryRegistry is AccessManagedUpgradeable, IHubPeripheryRegistry {
    /// @custom:storage-location erc7201:makina.storage.HubPeripheryRegistry
    struct HubPeripheryRegistryStorage {
        address _peripheryFactory;
        mapping(uint16 implemId => address depositor) _depositors;
        mapping(uint16 implemId => address redeemer) _redeemers;
        mapping(uint16 implemId => address feeManager) _feeManagers;
        address _securityModuleBeacon;
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
    function depositorBeacon(uint16 implemId) external view override returns (address) {
        return _getHubPeripheryRegistryStorage()._depositors[implemId];
    }

    /// @inheritdoc IHubPeripheryRegistry
    function redeemerBeacon(uint16 implemId) external view override returns (address) {
        return _getHubPeripheryRegistryStorage()._redeemers[implemId];
    }

    /// @inheritdoc IHubPeripheryRegistry
    function feeManagerBeacon(uint16 implemId) external view override returns (address) {
        return _getHubPeripheryRegistryStorage()._feeManagers[implemId];
    }

    /// @inheritdoc IHubPeripheryRegistry
    function securityModuleBeacon() external view override returns (address) {
        return _getHubPeripheryRegistryStorage()._securityModuleBeacon;
    }

    /// @inheritdoc IHubPeripheryRegistry
    function setPeripheryFactory(address _peripheryFactory) external override restricted {
        HubPeripheryRegistryStorage storage $ = _getHubPeripheryRegistryStorage();
        emit PeripheryFactoryChanged($._peripheryFactory, _peripheryFactory);
        $._peripheryFactory = _peripheryFactory;
    }

    /// @inheritdoc IHubPeripheryRegistry
    function setDepositorBeacon(uint16 implemId, address _depositorBeacon) external override restricted {
        HubPeripheryRegistryStorage storage $ = _getHubPeripheryRegistryStorage();
        emit DepositorBeaconChanged(implemId, $._depositors[implemId], _depositorBeacon);
        $._depositors[implemId] = _depositorBeacon;
    }

    /// @inheritdoc IHubPeripheryRegistry
    function setRedeemerBeacon(uint16 implemId, address _redeemerBeacon) external override restricted {
        HubPeripheryRegistryStorage storage $ = _getHubPeripheryRegistryStorage();
        emit RedeemerBeaconChanged(implemId, $._redeemers[implemId], _redeemerBeacon);
        $._redeemers[implemId] = _redeemerBeacon;
    }

    /// @inheritdoc IHubPeripheryRegistry
    function setFeeManagerBeacon(uint16 implemId, address _feeManagerBeacon) external override restricted {
        HubPeripheryRegistryStorage storage $ = _getHubPeripheryRegistryStorage();
        emit FeeManagerBeaconChanged(implemId, $._feeManagers[implemId], _feeManagerBeacon);
        $._feeManagers[implemId] = _feeManagerBeacon;
    }

    /// @inheritdoc IHubPeripheryRegistry
    function setSecurityModuleBeacon(address _securityModuleBeacon) external override restricted {
        HubPeripheryRegistryStorage storage $ = _getHubPeripheryRegistryStorage();
        emit SecurityModuleBeaconChanged($._securityModuleBeacon, _securityModuleBeacon);
        $._securityModuleBeacon = _securityModuleBeacon;
    }
}
