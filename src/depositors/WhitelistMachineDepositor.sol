/// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {IAccessManaged} from "@openzeppelin/contracts/access/manager/IAccessManaged.sol";

import {IMachineDepositor} from "../interfaces/IMachineDepositor.sol";
import {OpenMachineDepositor} from "./OpenMachineDepositor.sol";
import {Whitelist} from "../utils/Whitelist.sol";

contract WhitelistMachineDepositor is OpenMachineDepositor, Whitelist {
    constructor(address _registry) OpenMachineDepositor(_registry) {}

    /// @inheritdoc IAccessManaged
    function authority() public view override returns (address) {
        return IAccessManaged(machine()).authority();
    }

    /// @inheritdoc IMachineDepositor
    function deposit(uint256 assets, address receiver, uint256 minShares)
        public
        virtual
        override
        onlyWhitelistedUser
        returns (uint256)
    {
        return super.deposit(assets, receiver, minShares);
    }
}
