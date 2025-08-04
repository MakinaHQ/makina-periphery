// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {AccessManagedUpgradeable} from "@openzeppelin/contracts-upgradeable/access/manager/AccessManagedUpgradeable.sol";
import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";

import {IHubPeripheryFactory} from "../interfaces/IHubPeripheryFactory.sol";
import {IHubPeripheryRegistry} from "../interfaces/IHubPeripheryRegistry.sol";
import {IMachinePeriphery} from "../interfaces/IMachinePeriphery.sol";
import {Errors} from "../libraries/Errors.sol";
import {MakinaPeripheryContext} from "../utils/MakinaPeripheryContext.sol";

contract HubPeripheryFactory is AccessManagedUpgradeable, MakinaPeripheryContext, IHubPeripheryFactory {
    /// @custom:storage-location erc7201:makina.storage.HubPeripheryFactory
    struct HubPeripheryFactoryStorage {
        mapping(address machineDepositor => bool isMachineDepositor) _isMachineDepositor;
        mapping(address machineRedeemer => bool isMachineRedeemer) _isMachineRedeemer;
        mapping(address feeManager => bool isFeeManager) _isFeeManager;
        mapping(address machineDepositor => uint16 implemId) _machineDepositorImplemId;
        mapping(address machineRedeemer => uint16 implemId) _machineRedeemerImplemId;
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
    function isMachineDepositor(address _machineDepositor) external view override returns (bool) {
        return _getHubPeripheryFactoryStorage()._isMachineDepositor[_machineDepositor];
    }

    /// @inheritdoc IHubPeripheryFactory
    function isMachineRedeemer(address _machineRedeemer) external view override returns (bool) {
        return _getHubPeripheryFactoryStorage()._isMachineRedeemer[_machineRedeemer];
    }

    /// @inheritdoc IHubPeripheryFactory
    function isFeeManager(address _feeManager) external view override returns (bool) {
        return _getHubPeripheryFactoryStorage()._isFeeManager[_feeManager];
    }

    /// @inheritdoc IHubPeripheryFactory
    function machineDepositorImplemId(address _machineDepositor) external view override returns (uint16) {
        HubPeripheryFactoryStorage storage $ = _getHubPeripheryFactoryStorage();
        if (!$._isMachineDepositor[_machineDepositor]) {
            revert Errors.NotMachineDepositor();
        }
        return $._machineDepositorImplemId[_machineDepositor];
    }

    /// @inheritdoc IHubPeripheryFactory
    function machineRedeemerImplemId(address _machineRedeemer) external view override returns (uint16) {
        HubPeripheryFactoryStorage storage $ = _getHubPeripheryFactoryStorage();
        if (!$._isMachineRedeemer[_machineRedeemer]) {
            revert Errors.NotMachineRedeemer();
        }
        return $._machineRedeemerImplemId[_machineRedeemer];
    }

    /// @inheritdoc IHubPeripheryFactory
    function feeManagerImplemId(address _feeManager) external view override returns (uint16) {
        HubPeripheryFactoryStorage storage $ = _getHubPeripheryFactoryStorage();
        if (!$._isFeeManager[_feeManager]) {
            revert Errors.NotFeeManager();
        }
        return $._feeManagerImplemId[_feeManager];
    }

    function setMachine(address _machinePeriphery, address _machine) external restricted {
        HubPeripheryFactoryStorage storage $ = _getHubPeripheryFactoryStorage();

        if (
            !$._isMachineDepositor[_machinePeriphery] && !$._isMachineRedeemer[_machinePeriphery]
                && !$._isFeeManager[_machinePeriphery]
        ) {
            revert Errors.NotMachinePeriphery();
        }

        IMachinePeriphery(_machinePeriphery).setMachine(_machine);
    }

    /// @inheritdoc IHubPeripheryFactory
    function createMachineDepositor(uint16 _implemId, bytes calldata _initializationData)
        external
        override
        restricted
        returns (address)
    {
        HubPeripheryFactoryStorage storage $ = _getHubPeripheryFactoryStorage();

        address beacon = IHubPeripheryRegistry(peripheryRegistry).machineDepositorBeacon(_implemId);
        if (beacon == address(0)) {
            revert Errors.InvalidMachineDepositorImplemId();
        }

        address machineDepositor =
            address(new BeaconProxy(beacon, abi.encodeCall(IMachinePeriphery.initialize, (_initializationData))));

        $._isMachineDepositor[machineDepositor] = true;
        $._machineDepositorImplemId[machineDepositor] = _implemId;

        emit MachineDepositorCreated(machineDepositor, _implemId);

        return machineDepositor;
    }

    /// @inheritdoc IHubPeripheryFactory
    function createMachineRedeemer(uint16 _implemId, bytes calldata _initializationData)
        external
        override
        restricted
        returns (address)
    {
        HubPeripheryFactoryStorage storage $ = _getHubPeripheryFactoryStorage();

        address beacon = IHubPeripheryRegistry(peripheryRegistry).machineRedeemerBeacon(_implemId);
        if (beacon == address(0)) {
            revert Errors.InvalidMachineRedeemerImplemId();
        }

        address machineRedeemer =
            address(new BeaconProxy(beacon, abi.encodeCall(IMachinePeriphery.initialize, (_initializationData))));

        $._isMachineRedeemer[machineRedeemer] = true;
        $._machineRedeemerImplemId[machineRedeemer] = _implemId;

        emit MachineRedeemerCreated(machineRedeemer, _implemId);

        return machineRedeemer;
    }

    /// @inheritdoc IHubPeripheryFactory
    function createFeeManager(uint16 _implemId, bytes calldata _initializationData)
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

        address feeManager =
            address(new BeaconProxy(beacon, abi.encodeCall(IMachinePeriphery.initialize, (_initializationData))));

        $._isFeeManager[feeManager] = true;
        $._feeManagerImplemId[feeManager] = _implemId;

        emit FeeManagerCreated(feeManager, _implemId);

        return feeManager;
    }
}
