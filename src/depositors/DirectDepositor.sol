// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IMachine} from "@makina-core/interfaces/IMachine.sol";

import {IDirectDepositor} from "../interfaces/IDirectDepositor.sol";
import {ISanctionsList} from "../interfaces/ISanctionsList.sol";
import {IWhitelist} from "../interfaces/IWhitelist.sol";
import {MachinePeriphery} from "../utils/MachinePeriphery.sol";
import {SanctionsList} from "../utils/SanctionsList.sol";
import {Whitelist} from "../utils/Whitelist.sol";

contract DirectDepositor is MachinePeriphery, SanctionsList, Whitelist, IDirectDepositor {
    using SafeERC20 for IERC20;

    constructor(address _registry, address _sanctionsOracle)
        MachinePeriphery(_registry)
        SanctionsList(_sanctionsOracle)
    {}

    function initialize(bytes calldata data) external virtual override initializer {
        (bool _whitelistStatus, bool _sanctionsCheckStatus) = abi.decode(data, (bool, bool));
        __Whitelist_init(_whitelistStatus);
        __SanctionsList_init(_sanctionsCheckStatus);
    }

    /// @inheritdoc IDirectDepositor
    function deposit(uint256 assets, address receiver, uint256 minShares, bytes32 referralKey)
        public
        virtual
        override
        sanctionsCheck
        whitelistCheck
        returns (uint256)
    {
        address _machine = machine();
        address asset = IMachine(_machine).accountingToken();

        IERC20(asset).safeTransferFrom(msg.sender, address(this), assets);
        IERC20(asset).forceApprove(_machine, assets);

        return IMachine(_machine).deposit(assets, receiver, minShares, referralKey);
    }

    /// @inheritdoc IWhitelist
    function setWhitelistStatus(bool enabled) external override onlyRiskManager {
        _setWhitelistStatus(enabled);
    }

    /// @inheritdoc IWhitelist
    function setWhitelistedUsers(address[] calldata users, bool whitelisted) external override onlyRiskManager {
        _setWhitelistedUsers(users, whitelisted);
    }

    /// @inheritdoc ISanctionsList
    function setSanctionsCheckStatus(bool enabled) external override onlyRiskManager {
        _setSanctionsCheckStatus(enabled);
    }
}
