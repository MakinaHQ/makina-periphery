/// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {AccessManagedUpgradeable} from "@openzeppelin/contracts-upgradeable/access/manager/AccessManagedUpgradeable.sol";

import {CoreErrors} from "../libraries/Errors.sol";

import {IWhitelist} from "../interfaces/IWhitelist.sol";

abstract contract Whitelist is AccessManagedUpgradeable, IWhitelist {
    /// @custom:storage-location erc7201:makina.storage.Whitelist
    struct WhitelistStorage {
        mapping(address user => bool isWhitelisted) _isWhitelistedUser;
    }

    // keccak256(abi.encode(uint256(keccak256("makina.storage.Whitelist")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant WhitelistStorageLocation =
        0x8ecd71e87c506d6932770ce52ba8e8dc85963cc6e1a5097e1b32e68fbabfcb00;

    function _getWhitelistStorage() private pure returns (WhitelistStorage storage $) {
        assembly {
            $.slot := WhitelistStorageLocation
        }
    }

    modifier onlyWhitelistedUser() {
        if (!_getWhitelistStorage()._isWhitelistedUser[msg.sender]) {
            revert CoreErrors.UnauthorizedCaller();
        }
        _;
    }

    /// @inheritdoc IWhitelist
    function isWhitelistedUser(address user) public view override returns (bool) {
        return _getWhitelistStorage()._isWhitelistedUser[user];
    }

    /// @inheritdoc IWhitelist
    function setWhitelistedUsers(address[] calldata users, bool whitelisted) external override restricted {
        WhitelistStorage storage $ = _getWhitelistStorage();
        uint256 len = users.length;
        for (uint256 i = 0; i < len; ++i) {
            $._isWhitelistedUser[users[i]] = whitelisted;
            emit UserWhitelistingChanged(users[i], whitelisted);
        }
    }
}
