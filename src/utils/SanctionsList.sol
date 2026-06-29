// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {Errors} from "../libraries/Errors.sol";

import {IChainalysisSanctionsList} from "../interfaces/IChainalysisSanctionsList.sol";
import {ISanctionsList} from "../interfaces/ISanctionsList.sol";

abstract contract SanctionsList is Initializable, ISanctionsList {
    /// @inheritdoc ISanctionsList
    address public immutable override sanctionsOracle;

    /// @custom:storage-location erc7201:makina.storage.SanctionsList
    struct SanctionsListStorage {
        bool _isSanctionsCheckEnabled;
    }

    // keccak256(abi.encode(uint256(keccak256("makina.storage.SanctionsList")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant SanctionsListStorageLocation =
        0xeec6e327f8367f095b35862c656f521647a3faa26edd82f48dcb4d427059e600;

    function _getSanctionsListStorage() private pure returns (SanctionsListStorage storage $) {
        assembly {
            $.slot := SanctionsListStorageLocation
        }
    }

    constructor(address _sanctionsOracle) {
        sanctionsOracle = _sanctionsOracle;
    }

    function __SanctionsList_init(bool _initialSanctionsCheckStatus) internal onlyInitializing {
        SanctionsListStorage storage $ = _getSanctionsListStorage();
        $._isSanctionsCheckEnabled = _initialSanctionsCheckStatus;
    }

    modifier sanctionsCheck() {
        SanctionsListStorage storage $ = _getSanctionsListStorage();
        if ($._isSanctionsCheckEnabled && IChainalysisSanctionsList(sanctionsOracle).isSanctioned(msg.sender)) {
            revert Errors.SanctionedCaller();
        }
        _;
    }

    /// @inheritdoc ISanctionsList
    function isSanctionsCheckEnabled() public view override returns (bool) {
        return _getSanctionsListStorage()._isSanctionsCheckEnabled;
    }

    /// @dev Internal function to set the sanctions check status.
    function _setSanctionsCheckStatus(bool enabled) internal {
        SanctionsListStorage storage $ = _getSanctionsListStorage();
        if ($._isSanctionsCheckEnabled != enabled) {
            $._isSanctionsCheckEnabled = enabled;
            emit SanctionsCheckStatusChanged(enabled);
        }
    }
}
