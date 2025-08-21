/// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {IAccessManaged} from "@openzeppelin/contracts/access/manager/IAccessManaged.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IMachine} from "@makina-core/interfaces/IMachine.sol";

import {IDirectDepositor} from "../interfaces/IDirectDepositor.sol";
import {MachinePeriphery} from "../utils/MachinePeriphery.sol";
import {Whitelist} from "../utils/Whitelist.sol";

contract DirectDepositor is MachinePeriphery, Whitelist, IDirectDepositor {
    using SafeERC20 for IERC20;

    constructor(address _registry) MachinePeriphery(_registry) {
        _disableInitializers();
    }

    function initialize(bytes calldata data) external virtual override initializer {
        (bool _whitelistStatus) = abi.decode(data, (bool));
        __Whitelist_init(_whitelistStatus);
    }

    /// @inheritdoc IAccessManaged
    function authority() public view override returns (address) {
        return IAccessManaged(machine()).authority();
    }

    function deposit(uint256 assets, address receiver, uint256 minShares)
        public
        virtual
        override
        whitelistCheck
        returns (uint256)
    {
        address _machine = machine();
        address asset = IMachine(_machine).accountingToken();

        IERC20(asset).safeTransferFrom(msg.sender, address(this), assets);
        IERC20(asset).forceApprove(_machine, assets);

        return IMachine(_machine).deposit(assets, receiver, minShares);
    }
}
