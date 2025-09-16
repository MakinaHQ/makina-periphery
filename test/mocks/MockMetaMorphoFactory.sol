// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IMetaMorphoFactory} from "src/interfaces/IMetaMorphoFactory.sol";

/// @dev MockMetaMorphoFactory contract for testing use only
contract MockMetaMorphoFactory is IMetaMorphoFactory {
    function isMetaMorpho(address target) external pure returns (bool) {
        return target == address(0) ? false : true;
    }
}
