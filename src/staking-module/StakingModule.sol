// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {IERC20, IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IMachineShare} from "@makina-core/interfaces/IMachineShare.sol";
import {IOwnable2Step} from "@makina-core/interfaces/IOwnable2Step.sol";
import {DecimalsUtils} from "@makina-core/libraries/DecimalsUtils.sol";

import {MachinePeriphery} from "../utils/MachinePeriphery.sol";
import {IMachinePeriphery} from "../interfaces/IMachinePeriphery.sol";
import {IStakingModule} from "../interfaces/IStakingModule.sol";
import {Errors, CoreErrors} from "../libraries/Errors.sol";

contract StakingModule is ERC20Upgradeable, ReentrancyGuardUpgradeable, MachinePeriphery, IStakingModule {
    using Math for uint256;
    using SafeERC20 for IERC20;

    /// @dev Full scale value in basis points
    uint256 private constant MAX_BPS = 10_000;

    /// @custom:storage-location erc7201:makina.storage.StakingModule
    struct StakingModuleStorage {
        address _machineShare;
        uint256 _cooldownDuration;
        uint256 _maxSlashableBps;
        uint256 _minBalanceAfterSlash;
        mapping(address account => PendingCooldown cooldownData) _pendingCooldowns;
        bool _slashingMode;
    }

    // keccak256(abi.encode(uint256(keccak256("makina.storage.StakingModule")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant StakingModuleStorageLocation =
        0xcf807f880d1fce9d8a42cc80c71b5f1fe1909efcfcb3a5a3e4fe259e044a5f00;

    function _getStakingModuleStorage() private pure returns (StakingModuleStorage storage $) {
        assembly {
            $.slot := StakingModuleStorageLocation
        }
    }

    constructor(address _peripheryRegistry) MachinePeriphery(_peripheryRegistry) {}

    function initialize(bytes calldata _data) external virtual initializer {
        StakingModuleStorage storage $ = _getStakingModuleStorage();

        (StakingModuleInitParams memory smParams) = abi.decode(_data, (StakingModuleInitParams));

        $._machineShare = smParams.machineShare;
        $._cooldownDuration = smParams.initialCooldownDuration;
        if (smParams.initialMaxSlashableBps > MAX_BPS) {
            revert Errors.MaxBpsValueExceeded();
        }
        $._maxSlashableBps = smParams.initialMaxSlashableBps;
        $._minBalanceAfterSlash = smParams.initialMinBalanceAfterSlash;

        __ERC20_init(
            string(abi.encodePacked("Stake ", IERC20Metadata(smParams.machineShare).name())),
            string(abi.encodePacked("STK-", IERC20Metadata(smParams.machineShare).symbol()))
        );
    }

    modifier NotSlashingMode() {
        if (_getStakingModuleStorage()._slashingMode) {
            revert Errors.SlashingSettlementOngoing();
        }
        _;
    }

    /// @inheritdoc IERC20Metadata
    function decimals() public pure override returns (uint8) {
        return DecimalsUtils.SHARE_TOKEN_DECIMALS;
    }

    /// @inheritdoc IMachinePeriphery
    function machine() public view override(IMachinePeriphery, MachinePeriphery) returns (address) {
        return IOwnable2Step(_getStakingModuleStorage()._machineShare).owner();
    }

    /// @inheritdoc IStakingModule
    function machineShare() public view override returns (address) {
        return _getStakingModuleStorage()._machineShare;
    }

    /// @inheritdoc IStakingModule
    function cooldownDuration() public view override returns (uint256) {
        return _getStakingModuleStorage()._cooldownDuration;
    }

    /// @inheritdoc IStakingModule
    function maxSlashableBps() public view override returns (uint256) {
        return _getStakingModuleStorage()._maxSlashableBps;
    }

    /// @inheritdoc IStakingModule
    function minBalanceAfterSlash() public view override returns (uint256) {
        return _getStakingModuleStorage()._minBalanceAfterSlash;
    }

    /// @inheritdoc IStakingModule
    function pendingCooldown(address account) external view override returns (uint256 shares, uint256 maturity) {
        PendingCooldown memory request = _getStakingModuleStorage()._pendingCooldowns[account];
        return (request.shares, request.maturity);
    }

    /// @inheritdoc IStakingModule
    function slashingMode() public view override returns (bool) {
        return _getStakingModuleStorage()._slashingMode;
    }

    /// @inheritdoc IStakingModule
    function totalStakedAmount() public view override returns (uint256) {
        return IERC20(_getStakingModuleStorage()._machineShare).balanceOf(address(this));
    }

    /// @inheritdoc IStakingModule
    function maxSlashable() public view override returns (uint256) {
        StakingModuleStorage storage $ = _getStakingModuleStorage();

        uint256 totalStaked = totalStakedAmount();

        if (totalStaked <= $._minBalanceAfterSlash) {
            return 0;
        }

        uint256 capLimit = totalStaked.mulDiv($._maxSlashableBps, MAX_BPS);
        uint256 balanceLimit = totalStaked - $._minBalanceAfterSlash;

        return capLimit < balanceLimit ? capLimit : balanceLimit;
    }

    /// @inheritdoc IStakingModule
    function convertToShares(uint256 assets) public view override returns (uint256) {
        return assets.mulDiv(totalSupply() + 1, totalStakedAmount() + 1);
    }

    /// @inheritdoc IStakingModule
    function convertToAssets(uint256 shares) public view override returns (uint256) {
        return shares.mulDiv(totalStakedAmount() + 1, totalSupply() + 1);
    }

    /// @inheritdoc IStakingModule
    function previewStake(uint256 assets) public view override NotSlashingMode returns (uint256) {
        return convertToShares(assets);
    }

    /// @inheritdoc IStakingModule
    function stake(uint256 assets, address receiver, uint256 minShares)
        external
        override
        nonReentrant
        NotSlashingMode
        returns (uint256)
    {
        address account = msg.sender;
        uint256 shares = previewStake(assets);

        if (shares < minShares) {
            revert CoreErrors.SlippageProtection();
        }

        IERC20(_getStakingModuleStorage()._machineShare).safeTransferFrom(account, address(this), assets);
        _mint(receiver, shares);

        emit Stake(account, receiver, assets, shares);

        return shares;
    }

    /// @inheritdoc IStakingModule
    function redeem(address receiver, uint256 minAssets) external override nonReentrant returns (uint256) {
        StakingModuleStorage storage $ = _getStakingModuleStorage();

        address account = msg.sender;
        PendingCooldown memory pc = $._pendingCooldowns[account];

        if (block.timestamp < pc.maturity) {
            revert Errors.CooldownOngoing();
        }

        uint256 shares = pc.shares;
        uint256 assets = convertToAssets(shares);
        assets = assets < pc.maxAssets ? assets : pc.maxAssets;

        if (assets < minAssets) {
            revert CoreErrors.SlippageProtection();
        }

        delete $._pendingCooldowns[account];
        _burn(account, shares);
        IERC20($._machineShare).safeTransfer(receiver, assets);

        emit Redeem(account, receiver, assets, shares);

        return assets;
    }

    /// @inheritdoc IStakingModule
    function startCooldown(uint256 shares) external override nonReentrant returns (uint256) {
        StakingModuleStorage storage $ = _getStakingModuleStorage();

        address account = msg.sender;
        uint256 assets = convertToAssets(shares);
        uint256 maturity = block.timestamp + $._cooldownDuration;

        $._pendingCooldowns[account] = PendingCooldown({shares: shares, maxAssets: assets, maturity: maturity});

        emit Cooldown(account, shares, maturity);

        return maturity;
    }

    /// @inheritdoc IStakingModule
    function slash(uint256 amount) external override nonReentrant onlySecurityCouncil {
        StakingModuleStorage storage $ = _getStakingModuleStorage();

        if (amount > maxSlashable()) {
            revert Errors.MaxSlashableExceeded();
        }

        IMachineShare($._machineShare).burn(address(this), amount);

        $._slashingMode = true;

        emit Slash(amount);
    }

    /// @inheritdoc IStakingModule
    function settleSlashing() external override onlySecurityCouncil {
        _getStakingModuleStorage()._slashingMode = false;
        emit SlashingSettled();
    }

    /// @inheritdoc IStakingModule
    function setCooldownDuration(uint256 newCooldownDuration) external override onlyRiskManager {
        StakingModuleStorage storage $ = _getStakingModuleStorage();
        emit CooldownDurationChanged($._cooldownDuration, newCooldownDuration);
        $._cooldownDuration = newCooldownDuration;
    }

    /// @inheritdoc IStakingModule
    function setMaxSlashableBps(uint256 newMaxSlashableBps) external override onlyRiskManager {
        StakingModuleStorage storage $ = _getStakingModuleStorage();
        if (newMaxSlashableBps > MAX_BPS) {
            revert Errors.MaxBpsValueExceeded();
        }
        emit MaxSlashableBpsChanged($._maxSlashableBps, newMaxSlashableBps);
        $._maxSlashableBps = newMaxSlashableBps;
    }

    /// @inheritdoc IStakingModule
    function setMinBalanceAfterSlash(uint256 newMinBalanceAfterSlash) external override onlyRiskManager {
        StakingModuleStorage storage $ = _getStakingModuleStorage();
        emit MinBalanceAfterSlashChanged($._minBalanceAfterSlash, newMinBalanceAfterSlash);
        $._minBalanceAfterSlash = newMinBalanceAfterSlash;
    }

    /// @dev Disables machine setter from parent MachinePeriphery contract.
    function _setMachine(address) internal pure override {
        revert Errors.NotImplemented();
    }
}
