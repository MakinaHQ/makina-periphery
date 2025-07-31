/// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {IAccessManaged} from "@openzeppelin/contracts/access/manager/IAccessManaged.sol";

import {AsyncMachineRedeemer} from "./AsyncMachineRedeemer.sol";
import {IAsyncMachineRedeemer} from "../interfaces/IAsyncMachineRedeemer.sol";
import {Whitelist} from "../utils/Whitelist.sol";

contract WhitelistAsyncMachineRedeemer is AsyncMachineRedeemer, Whitelist {
    constructor(address _registry) AsyncMachineRedeemer(_registry) {}

    /// @inheritdoc IAccessManaged
    function authority() public view override returns (address) {
        return IAccessManaged(machine()).authority();
    }

    /// @inheritdoc IAsyncMachineRedeemer
    function requestRedeem(uint256 shares, address recipient) public override onlyWhitelistedUser returns (uint256) {
        return super.requestRedeem(shares, recipient);
    }
}
