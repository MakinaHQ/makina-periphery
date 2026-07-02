// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IChainalysisSanctionsList} from "src/interfaces/IChainalysisSanctionsList.sol";

/// @dev MockChainalysisSanctionsList contract for testing use only
contract MockChainalysisSanctionsList is IChainalysisSanctionsList {
    mapping(address account => bool sanctioned) private _isSanctioned;

    function isSanctioned(address addr) external view override returns (bool) {
        return _isSanctioned[addr];
    }

    function setSanctioned(address addr, bool sanctioned) external {
        _isSanctioned[addr] = sanctioned;
    }
}
