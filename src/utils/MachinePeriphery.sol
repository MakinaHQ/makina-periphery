// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {IMakinaGovernable} from "@makina-core/interfaces/IMakinaGovernable.sol";

import {Errors, CoreErrors} from "../libraries/Errors.sol";
import {MakinaPeripheryContext} from "./MakinaPeripheryContext.sol";
import {IHubPeripheryRegistry} from "../interfaces/IHubPeripheryRegistry.sol";
import {IMachinePeriphery} from "../interfaces/IMachinePeriphery.sol";

abstract contract MachinePeriphery is Initializable, MakinaPeripheryContext, IMachinePeriphery {
    /// @custom:storage-location erc7201:makina.storage.MachinePeriphery
    struct MachinePeripheryStorage {
        address _machine;
    }

    // keccak256(abi.encode(uint256(keccak256("makina.storage.MachinePeriphery")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant MachinePeripheryStorageLocation =
        0xf8e170f38959918ab7e583dba012d1b8610047e073c7ca874900b1e0c133c900;

    function _getMachinePeripheryStorage() internal pure returns (MachinePeripheryStorage storage $) {
        assembly {
            $.slot := MachinePeripheryStorageLocation
        }
    }

    constructor(address _peripheryRegistry) MakinaPeripheryContext(_peripheryRegistry) {
        _disableInitializers();
    }

    modifier onlyFactory() {
        if (msg.sender != IHubPeripheryRegistry(peripheryRegistry).peripheryFactory()) {
            revert CoreErrors.NotFactory();
        }
        _;
    }

    modifier onlyMechanic() {
        if (msg.sender != IMakinaGovernable(machine()).mechanic()) {
            revert CoreErrors.UnauthorizedCaller();
        }
        _;
    }

    modifier onlySecurityCouncil() {
        if (msg.sender != IMakinaGovernable(machine()).securityCouncil()) {
            revert CoreErrors.UnauthorizedCaller();
        }
        _;
    }

    modifier onlyRiskManager() {
        if (msg.sender != IMakinaGovernable(machine()).riskManager()) {
            revert CoreErrors.UnauthorizedCaller();
        }
        _;
    }

    modifier onlyRiskManagerTimelock() {
        if (msg.sender != IMakinaGovernable(machine()).riskManagerTimelock()) {
            revert CoreErrors.UnauthorizedCaller();
        }
        _;
    }

    /// @inheritdoc IMachinePeriphery
    function machine() public view virtual returns (address) {
        address _machine = _getMachinePeripheryStorage()._machine;
        if (_machine == address(0)) {
            revert Errors.MachineNotSet();
        }
        return _machine;
    }

    /// @inheritdoc IMachinePeriphery
    function setMachine(address _machine) external onlyFactory {
        _setMachine(_machine);
    }

    /// @dev Sets the machine this contract is associated with.
    function _setMachine(address _machine) internal virtual {
        MachinePeripheryStorage storage $ = _getMachinePeripheryStorage();
        if ($._machine != address(0)) {
            revert Errors.MachineAlreadySet();
        }
        if (_machine == address(0)) {
            revert Errors.ZeroMachineAddress();
        }
        $._machine = _machine;

        emit MachineSet(_machine);
    }
}
