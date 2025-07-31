/// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IMachine} from "@makina-core/interfaces/IMachine.sol";

import {IMachineDepositor} from "../interfaces/IMachineDepositor.sol";
import {MachinePeriphery} from "../utils/MachinePeriphery.sol";

contract OpenMachineDepositor is MachinePeriphery, IMachineDepositor {
    using SafeERC20 for IERC20;

    constructor(address _registry) MachinePeriphery(_registry) {
        _disableInitializers();
    }

    function initialize(bytes calldata) external virtual override initializer {}

    function deposit(uint256 assets, address receiver, uint256 minShares) public virtual override returns (uint256) {
        address _machine = machine();
        address asset = IMachine(_machine).accountingToken();

        IERC20(asset).safeTransferFrom(msg.sender, address(this), assets);
        IERC20(asset).forceApprove(_machine, assets);

        return IMachine(_machine).deposit(assets, receiver, minShares);
    }
}
