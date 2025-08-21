// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {AccessManagedUpgradeable} from "@openzeppelin/contracts-upgradeable/access/manager/AccessManagedUpgradeable.sol";
import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";

import {IHubPeripheryFactory} from "../interfaces/IHubPeripheryFactory.sol";
import {IHubPeripheryRegistry} from "../interfaces/IHubPeripheryRegistry.sol";
import {IStakingModuleReference} from "../interfaces/IStakingModuleReference.sol";
import {IMachinePeriphery} from "../interfaces/IMachinePeriphery.sol";
import {IStakingModule} from "../interfaces/IStakingModule.sol";
import {Errors} from "../libraries/Errors.sol";
import {MakinaPeripheryContext} from "../utils/MakinaPeripheryContext.sol";

contract HubPeripheryFactory is AccessManagedUpgradeable, MakinaPeripheryContext, IHubPeripheryFactory {
    /// @custom:storage-location erc7201:makina.storage.HubPeripheryFactory
    struct HubPeripheryFactoryStorage {
        mapping(address depositor => bool isDepositor) _isDepositor;
        mapping(address redeemer => bool isRedeemer) _isRedeemer;
        mapping(address feeManager => bool isFeeManager) _isFeeManager;
        mapping(address stakingModule => bool isStakingModule) _isStakingModule;
        mapping(address depositor => uint16 implemId) _depositorImplemId;
        mapping(address redeemer => uint16 implemId) _redeemerImplemId;
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
    function isDepositor(address _depositor) external view override returns (bool) {
        return _getHubPeripheryFactoryStorage()._isDepositor[_depositor];
    }

    /// @inheritdoc IHubPeripheryFactory
    function isRedeemer(address _redeemer) external view override returns (bool) {
        return _getHubPeripheryFactoryStorage()._isRedeemer[_redeemer];
    }

    /// @inheritdoc IHubPeripheryFactory
    function isFeeManager(address _feeManager) external view override returns (bool) {
        return _getHubPeripheryFactoryStorage()._isFeeManager[_feeManager];
    }

    /// @inheritdoc IHubPeripheryFactory
    function isStakingModule(address _stakingModule) external view override returns (bool) {
        return _getHubPeripheryFactoryStorage()._isStakingModule[_stakingModule];
    }

    /// @inheritdoc IHubPeripheryFactory
    function depositorImplemId(address _depositor) external view override returns (uint16) {
        HubPeripheryFactoryStorage storage $ = _getHubPeripheryFactoryStorage();
        if (!$._isDepositor[_depositor]) {
            revert Errors.NotDepositor();
        }
        return $._depositorImplemId[_depositor];
    }

    /// @inheritdoc IHubPeripheryFactory
    function redeemerImplemId(address _redeemer) external view override returns (uint16) {
        HubPeripheryFactoryStorage storage $ = _getHubPeripheryFactoryStorage();
        if (!$._isRedeemer[_redeemer]) {
            revert Errors.NotRedeemer();
        }
        return $._redeemerImplemId[_redeemer];
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
    function setMachine(address machinePeriphery, address machine) external override restricted {
        HubPeripheryFactoryStorage storage $ = _getHubPeripheryFactoryStorage();

        if (
            !$._isDepositor[machinePeriphery] && !$._isRedeemer[machinePeriphery] && !$._isFeeManager[machinePeriphery]
                && !$._isStakingModule[machinePeriphery]
        ) {
            revert Errors.NotMachinePeriphery();
        }

        IMachinePeriphery(machinePeriphery).setMachine(machine);
    }

    /// @inheritdoc IHubPeripheryFactory
    function setStakingModule(address feeManager, address stakingModule) external override restricted {
        HubPeripheryFactoryStorage storage $ = _getHubPeripheryFactoryStorage();

        if (!$._isFeeManager[feeManager]) {
            revert Errors.NotFeeManager();
        }

        if (!$._isStakingModule[stakingModule]) {
            revert Errors.NotStakingModule();
        }

        IStakingModuleReference(feeManager).setStakingModule(stakingModule);
    }

    /// @inheritdoc IHubPeripheryFactory
    function createDepositor(uint16 _implemId, bytes calldata _initializationData)
        external
        override
        restricted
        returns (address)
    {
        HubPeripheryFactoryStorage storage $ = _getHubPeripheryFactoryStorage();

        address beacon = IHubPeripheryRegistry(peripheryRegistry).depositorBeacon(_implemId);
        if (beacon == address(0)) {
            revert Errors.InvalidDepositorImplemId();
        }

        address depositor =
            address(new BeaconProxy(beacon, abi.encodeCall(IMachinePeriphery.initialize, (_initializationData))));

        $._isDepositor[depositor] = true;
        $._depositorImplemId[depositor] = _implemId;

        emit DepositorCreated(depositor, _implemId);

        return depositor;
    }

    /// @inheritdoc IHubPeripheryFactory
    function createRedeemer(uint16 _implemId, bytes calldata _initializationData)
        external
        override
        restricted
        returns (address)
    {
        HubPeripheryFactoryStorage storage $ = _getHubPeripheryFactoryStorage();

        address beacon = IHubPeripheryRegistry(peripheryRegistry).redeemerBeacon(_implemId);
        if (beacon == address(0)) {
            revert Errors.InvalidRedeemerImplemId();
        }

        address redeemer =
            address(new BeaconProxy(beacon, abi.encodeCall(IMachinePeriphery.initialize, (_initializationData))));

        $._isRedeemer[redeemer] = true;
        $._redeemerImplemId[redeemer] = _implemId;

        emit RedeemerCreated(redeemer, _implemId);

        return redeemer;
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

    /// @inheritdoc IHubPeripheryFactory
    function createStakingModule(IStakingModule.StakingModuleInitParams calldata smParams)
        external
        override
        restricted
        returns (address)
    {
        HubPeripheryFactoryStorage storage $ = _getHubPeripheryFactoryStorage();

        address stakingModule = address(
            new BeaconProxy(
                IHubPeripheryRegistry(peripheryRegistry).stakingModuleBeacon(),
                abi.encodeCall(IMachinePeriphery.initialize, (abi.encode(smParams)))
            )
        );

        $._isStakingModule[stakingModule] = true;

        emit StakingModuleCreated(stakingModule);

        return stakingModule;
    }
}
