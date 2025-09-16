// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {CoreErrors} from "../libraries/Errors.sol";

import {IWhitelist} from "../interfaces/IWhitelist.sol";

abstract contract Whitelist is Initializable, IWhitelist {
    /// @custom:storage-location erc7201:makina.storage.Whitelist
    struct WhitelistStorage {
        mapping(address user => bool isWhitelisted) _isWhitelistedUser;
        bool _isWhitelistEnabled;
    }

    // keccak256(abi.encode(uint256(keccak256("makina.storage.Whitelist")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant WhitelistStorageLocation =
        0x8ecd71e87c506d6932770ce52ba8e8dc85963cc6e1a5097e1b32e68fbabfcb00;

    function _getWhitelistStorage() private pure returns (WhitelistStorage storage $) {
        assembly {
            $.slot := WhitelistStorageLocation
        }
    }

    function __Whitelist_init(bool _initialWhitelistStatus) internal onlyInitializing {
        WhitelistStorage storage $ = _getWhitelistStorage();
        $._isWhitelistEnabled = _initialWhitelistStatus;
    }

    modifier whitelistCheck() {
        WhitelistStorage storage $ = _getWhitelistStorage();
        if ($._isWhitelistEnabled && !$._isWhitelistedUser[msg.sender]) {
            revert CoreErrors.UnauthorizedCaller();
        }
        _;
    }

    /// @inheritdoc IWhitelist
    function isWhitelistEnabled() public view returns (bool) {
        return _getWhitelistStorage()._isWhitelistEnabled;
    }

    /// @inheritdoc IWhitelist
    function isWhitelistedUser(address user) public view override returns (bool) {
        return _getWhitelistStorage()._isWhitelistedUser[user];
    }

    /// @dev Internal function to set the whitelist status.
    function _setWhitelistStatus(bool enabled) internal {
        WhitelistStorage storage $ = _getWhitelistStorage();
        if ($._isWhitelistEnabled != enabled) {
            $._isWhitelistEnabled = enabled;
            emit WhitelistStatusChanged(enabled);
        }
    }

    /// @dev Internal function to set the whitelisted users.
    function _setWhitelistedUsers(address[] calldata users, bool whitelisted) internal {
        WhitelistStorage storage $ = _getWhitelistStorage();
        uint256 len = users.length;
        for (uint256 i = 0; i < len; ++i) {
            if ($._isWhitelistedUser[users[i]] != whitelisted) {
                $._isWhitelistedUser[users[i]] = whitelisted;
                emit UserWhitelistingChanged(users[i], whitelisted);
            }
        }
    }
}
