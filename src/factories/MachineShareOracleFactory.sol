// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {AccessManagedUpgradeable} from "@openzeppelin/contracts-upgradeable/access/manager/AccessManagedUpgradeable.sol";
import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";

import {IMachineShareOracle} from "../interfaces/IMachineShareOracle.sol";
import {IMachineShareOracleFactory} from "../interfaces/IMachineShareOracleFactory.sol";

contract MachineShareOracleFactory is AccessManagedUpgradeable, IMachineShareOracleFactory {
    // @custom:storage-location erc7201:makina.storage.MachineShareOracleFactory
    struct MachineShareOracleFactoryStorage {
        mapping(address oracle => bool isOracle) _isMachineShareOracle;
        address _machineShareOracleBeacon;
    }

    // keccak256(abi.encode(uint256(keccak256("makina.storage.MachineShareOracleFactory")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant MachineShareOracleFactoryStorageLocation =
        0x566402f20de4969fde1c09f6ddbae1c0f5590a4d61e4a12b6deb88f69bf7c700;

    function _getMachineShareOracleFactoryStorage()
        internal
        pure
        returns (MachineShareOracleFactoryStorage storage $)
    {
        assembly {
            $.slot := MachineShareOracleFactoryStorageLocation
        }
    }

    constructor() {
        _disableInitializers();
    }

    function initialize(address _machineShareOracleBeacon, address _initialAuthority) external initializer {
        _getMachineShareOracleFactoryStorage()._machineShareOracleBeacon = _machineShareOracleBeacon;
        __AccessManaged_init(_initialAuthority);
    }

    /// @inheritdoc IMachineShareOracleFactory
    function machineShareOracleBeacon() external view returns (address) {
        return _getMachineShareOracleFactoryStorage()._machineShareOracleBeacon;
    }

    /// @inheritdoc IMachineShareOracleFactory
    function isMachineShareOracle(address oracle) external view returns (bool) {
        return _getMachineShareOracleFactoryStorage()._isMachineShareOracle[oracle];
    }

    /// @inheritdoc IMachineShareOracleFactory
    function createMachineShareOracle(address shareOwner, uint8 decimals) external restricted returns (address) {
        MachineShareOracleFactoryStorage storage $ = _getMachineShareOracleFactoryStorage();

        address oracle = address(
            new BeaconProxy(
                $._machineShareOracleBeacon, abi.encodeCall(IMachineShareOracle.initialize, (shareOwner, decimals))
            )
        );
        $._isMachineShareOracle[oracle] = true;

        emit MachineShareOracleCreated(oracle);

        return oracle;
    }

    /// @inheritdoc IMachineShareOracleFactory
    function setMachineShareOracleBeacon(address _machineShareOracleBeacon) external restricted {
        MachineShareOracleFactoryStorage storage $ = _getMachineShareOracleFactoryStorage();
        emit MachineShareOracleBeaconChanged($._machineShareOracleBeacon, _machineShareOracleBeacon);
        $._machineShareOracleBeacon = _machineShareOracleBeacon;
    }
}
