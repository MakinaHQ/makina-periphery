// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {IERC20, IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IERC721Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IMachineShare} from "@makina-core/interfaces/IMachineShare.sol";
import {IOwnable2Step} from "@makina-core/interfaces/IOwnable2Step.sol";
import {DecimalsUtils} from "@makina-core/libraries/DecimalsUtils.sol";

import {MachinePeriphery} from "../utils/MachinePeriphery.sol";
import {IMachinePeriphery} from "../interfaces/IMachinePeriphery.sol";
import {ISecurityModule} from "../interfaces/ISecurityModule.sol";
import {ISMCooldownReceipt} from "../interfaces/ISMCooldownReceipt.sol";
import {Errors, CoreErrors} from "../libraries/Errors.sol";

contract SecurityModule is ERC20Upgradeable, ReentrancyGuardUpgradeable, MachinePeriphery, ISecurityModule {
    using Math for uint256;
    using SafeERC20 for IERC20;

    /// @dev Full scale value in basis points
    uint256 private constant MAX_BPS = 10_000;

    /// @custom:storage-location erc7201:makina.storage.SecurityModule
    struct SecurityModuleStorage {
        address _machineShare;
        address _cooldownReceipt;
        uint256 _cooldownDuration;
        uint256 _maxSlashableBps;
        uint256 _minBalanceAfterSlash;
        mapping(uint256 cooldownId => PendingCooldown cooldownData) _pendingCooldowns;
        bool _slashingMode;
    }

    // keccak256(abi.encode(uint256(keccak256("makina.storage.SecurityModule")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant SecurityModuleStorageLocation =
        0x008282b5c1b058474ce5feb89ba7468762b87f27435b2f525bf76e3e0c3af500;

    function _getSecurityModuleStorage() private pure returns (SecurityModuleStorage storage $) {
        assembly {
            $.slot := SecurityModuleStorageLocation
        }
    }

    constructor(address _peripheryRegistry) MachinePeriphery(_peripheryRegistry) {}

    function initialize(bytes calldata _data) external virtual initializer {
        SecurityModuleStorage storage $ = _getSecurityModuleStorage();

        (SecurityModuleInitParams memory smParams, address _cooldownReceipt) =
            abi.decode(_data, (SecurityModuleInitParams, address));

        $._machineShare = smParams.machineShare;
        $._cooldownDuration = smParams.initialCooldownDuration;
        if (smParams.initialMaxSlashableBps > MAX_BPS) {
            revert Errors.MaxBpsValueExceeded();
        }
        $._maxSlashableBps = smParams.initialMaxSlashableBps;
        $._minBalanceAfterSlash = smParams.initialMinBalanceAfterSlash;

        __ERC20_init(
            string(abi.encodePacked("Security Module: ", IERC20Metadata(smParams.machineShare).name())),
            string(abi.encodePacked("sm", IERC20Metadata(smParams.machineShare).symbol()))
        );

        IOwnable2Step(_cooldownReceipt).acceptOwnership();
        $._cooldownReceipt = _cooldownReceipt;
    }

    modifier NotSlashingMode() {
        if (_getSecurityModuleStorage()._slashingMode) {
            revert Errors.SlashingSettlementOngoing();
        }
        _;
    }

    /// @inheritdoc IERC20Metadata
    function decimals() public pure override(ERC20Upgradeable, IERC20Metadata) returns (uint8) {
        return DecimalsUtils.SHARE_TOKEN_DECIMALS;
    }

    /// @inheritdoc IMachinePeriphery
    function machine() public view override(IMachinePeriphery, MachinePeriphery) returns (address) {
        return IOwnable2Step(_getSecurityModuleStorage()._machineShare).owner();
    }

    /// @inheritdoc ISecurityModule
    function machineShare() public view override returns (address) {
        return _getSecurityModuleStorage()._machineShare;
    }

    /// @inheritdoc ISecurityModule
    function cooldownReceipt() public view override returns (address) {
        return _getSecurityModuleStorage()._cooldownReceipt;
    }

    /// @inheritdoc ISecurityModule
    function cooldownDuration() public view override returns (uint256) {
        return _getSecurityModuleStorage()._cooldownDuration;
    }

    /// @inheritdoc ISecurityModule
    function maxSlashableBps() public view override returns (uint256) {
        return _getSecurityModuleStorage()._maxSlashableBps;
    }

    /// @inheritdoc ISecurityModule
    function minBalanceAfterSlash() public view override returns (uint256) {
        return _getSecurityModuleStorage()._minBalanceAfterSlash;
    }

    /// @inheritdoc ISecurityModule
    function pendingCooldown(uint256 cooldownId) external view override returns (uint256, uint256, uint256) {
        SecurityModuleStorage storage $ = _getSecurityModuleStorage();

        // check that the cooldown receipt exists
        ISMCooldownReceipt($._cooldownReceipt).ownerOf(cooldownId);

        PendingCooldown memory pc = $._pendingCooldowns[cooldownId];

        uint256 currentAssets = convertToAssets(pc.shares);
        currentAssets = currentAssets < pc.maxAssets ? currentAssets : pc.maxAssets;

        return (pc.shares, currentAssets, pc.maturity);
    }

    /// @inheritdoc ISecurityModule
    function slashingMode() public view override returns (bool) {
        return _getSecurityModuleStorage()._slashingMode;
    }

    /// @inheritdoc ISecurityModule
    function totalLockedAmount() public view override returns (uint256) {
        return IERC20(_getSecurityModuleStorage()._machineShare).balanceOf(address(this));
    }

    /// @inheritdoc ISecurityModule
    function maxSlashable() public view override returns (uint256) {
        SecurityModuleStorage storage $ = _getSecurityModuleStorage();

        uint256 totalLocked = totalLockedAmount();

        if (totalLocked <= $._minBalanceAfterSlash) {
            return 0;
        }

        uint256 capLimit = totalLocked.mulDiv($._maxSlashableBps, MAX_BPS);
        uint256 balanceLimit = totalLocked - $._minBalanceAfterSlash;

        return capLimit < balanceLimit ? capLimit : balanceLimit;
    }

    /// @inheritdoc ISecurityModule
    function convertToShares(uint256 assets) public view override returns (uint256) {
        return assets.mulDiv(totalSupply() + 1, totalLockedAmount() + 1);
    }

    /// @inheritdoc ISecurityModule
    function convertToAssets(uint256 shares) public view override returns (uint256) {
        return shares.mulDiv(totalLockedAmount() + 1, totalSupply() + 1);
    }

    /// @inheritdoc ISecurityModule
    function previewLock(uint256 assets) public view override NotSlashingMode returns (uint256) {
        return convertToShares(assets);
    }

    /// @inheritdoc ISecurityModule
    function lock(uint256 assets, address receiver, uint256 minShares)
        external
        override
        nonReentrant
        NotSlashingMode
        returns (uint256)
    {
        address caller = msg.sender;
        uint256 shares = previewLock(assets);

        if (shares < minShares) {
            revert CoreErrors.SlippageProtection();
        }

        IERC20(_getSecurityModuleStorage()._machineShare).safeTransferFrom(caller, address(this), assets);
        _mint(receiver, shares);

        emit Lock(caller, receiver, assets, shares);

        return shares;
    }

    /// @inheritdoc ISecurityModule
    function startCooldown(uint256 shares, address receiver)
        external
        override
        nonReentrant
        returns (uint256, uint256, uint256)
    {
        SecurityModuleStorage storage $ = _getSecurityModuleStorage();

        address caller = msg.sender;

        if (shares == 0) {
            revert Errors.ZeroShares();
        }

        uint256 assets = convertToAssets(shares);
        uint256 maturity = block.timestamp + $._cooldownDuration;

        _transfer(caller, address(this), shares);
        uint256 cooldownId = ISMCooldownReceipt($._cooldownReceipt).mint(receiver);
        $._pendingCooldowns[cooldownId] = PendingCooldown({shares: shares, maxAssets: assets, maturity: maturity});

        emit Cooldown(cooldownId, caller, receiver, shares, maturity);

        return (cooldownId, assets, maturity);
    }

    /// @inheritdoc ISecurityModule
    function cancelCooldown(uint256 cooldownId) external override nonReentrant returns (uint256) {
        SecurityModuleStorage storage $ = _getSecurityModuleStorage();

        address receiver = _checkReceiptOwner(cooldownId);

        PendingCooldown memory pc = $._pendingCooldowns[cooldownId];

        if (block.timestamp >= pc.maturity) {
            revert Errors.CooldownExpired();
        }

        uint256 shares = pc.shares;

        delete $._pendingCooldowns[cooldownId];
        _transfer(address(this), receiver, shares);
        ISMCooldownReceipt($._cooldownReceipt).burn(cooldownId);

        emit CooldownCancelled(cooldownId, receiver, shares);

        return shares;
    }

    /// @inheritdoc ISecurityModule
    function redeem(uint256 cooldownId, uint256 minAssets) external override nonReentrant returns (uint256) {
        SecurityModuleStorage storage $ = _getSecurityModuleStorage();

        address receiver = _checkReceiptOwner(cooldownId);

        PendingCooldown memory pc = $._pendingCooldowns[cooldownId];

        if (block.timestamp < pc.maturity) {
            revert Errors.CooldownOngoing();
        }

        uint256 shares = pc.shares;
        uint256 assets = convertToAssets(shares);
        assets = assets < pc.maxAssets ? assets : pc.maxAssets;

        if (assets < minAssets) {
            revert CoreErrors.SlippageProtection();
        }

        delete $._pendingCooldowns[cooldownId];
        _burn(address(this), shares);
        ISMCooldownReceipt($._cooldownReceipt).burn(cooldownId);
        IERC20($._machineShare).safeTransfer(receiver, assets);

        emit Redeem(cooldownId, receiver, assets, shares);

        return assets;
    }

    /// @inheritdoc ISecurityModule
    function slash(uint256 amount) external override nonReentrant onlySecurityCouncil {
        SecurityModuleStorage storage $ = _getSecurityModuleStorage();

        if (amount > maxSlashable()) {
            revert Errors.MaxSlashableExceeded();
        }

        IMachineShare($._machineShare).burn(address(this), amount);

        $._slashingMode = true;

        emit Slash(amount);
    }

    /// @inheritdoc ISecurityModule
    function settleSlashing() external override onlySecurityCouncil {
        _getSecurityModuleStorage()._slashingMode = false;
        emit SlashingSettled();
    }

    /// @inheritdoc ISecurityModule
    function setCooldownDuration(uint256 newCooldownDuration) external override onlyRiskManagerTimelock {
        SecurityModuleStorage storage $ = _getSecurityModuleStorage();
        emit CooldownDurationChanged($._cooldownDuration, newCooldownDuration);
        $._cooldownDuration = newCooldownDuration;
    }

    /// @inheritdoc ISecurityModule
    function setMaxSlashableBps(uint256 newMaxSlashableBps) external override onlyRiskManagerTimelock {
        SecurityModuleStorage storage $ = _getSecurityModuleStorage();
        if (newMaxSlashableBps > MAX_BPS) {
            revert Errors.MaxBpsValueExceeded();
        }
        emit MaxSlashableBpsChanged($._maxSlashableBps, newMaxSlashableBps);
        $._maxSlashableBps = newMaxSlashableBps;
    }

    /// @inheritdoc ISecurityModule
    function setMinBalanceAfterSlash(uint256 newMinBalanceAfterSlash) external override onlyRiskManagerTimelock {
        SecurityModuleStorage storage $ = _getSecurityModuleStorage();
        emit MinBalanceAfterSlashChanged($._minBalanceAfterSlash, newMinBalanceAfterSlash);
        $._minBalanceAfterSlash = newMinBalanceAfterSlash;
    }

    /// @dev Disables machine setter from parent MachinePeriphery contract.
    function _setMachine(address) internal pure override {
        revert Errors.NotImplemented();
    }

    /// @dev Checks that caller is the owner of the cooldown receipt NFT.
    function _checkReceiptOwner(uint256 cooldownId) internal view returns (address) {
        address receiver = ISMCooldownReceipt(_getSecurityModuleStorage()._cooldownReceipt).ownerOf(cooldownId);
        if (msg.sender != receiver) {
            revert IERC721Errors.ERC721IncorrectOwner(msg.sender, cooldownId, receiver);
        }
        return receiver;
    }
}
