// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import {IMachine} from "@makina-core/interfaces/IMachine.sol";

import {Errors} from "../libraries/Errors.sol";
import {MachinePeriphery} from "../utils/MachinePeriphery.sol";
import {Whitelist} from "../utils/Whitelist.sol";
import {IAsyncRedeemer} from "../interfaces/IAsyncRedeemer.sol";
import {IMachinePeriphery} from "../interfaces/IMachinePeriphery.sol";
import {IWhitelist} from "../interfaces/IWhitelist.sol";

contract AsyncRedeemer is ERC721Upgradeable, ReentrancyGuardUpgradeable, MachinePeriphery, Whitelist, IAsyncRedeemer {
    using Math for uint256;
    using SafeERC20 for IERC20;

    /// @custom:storage-location erc7201:makina.storage.AsyncRedeemer
    struct AsyncRedeemerStorage {
        uint256 _nextRequestId;
        uint256 _lastFinalizedRequestId;
        uint256 _finalizationDelay;
        mapping(uint256 requestId => IAsyncRedeemer.RedeemRequest request) _requests;
    }

    // keccak256(abi.encode(uint256(keccak256("makina.storage.AsyncRedeemer")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant AsyncRedeemerStorageLocation =
        0x187c268ec5d498b5b6e4945b27f62abf37217cdbd80e6429181b3e4c2c378900;

    function _getAsyncRedeemerStorage() private pure returns (AsyncRedeemerStorage storage $) {
        assembly {
            $.slot := AsyncRedeemerStorageLocation
        }
    }

    constructor(address _registry) MachinePeriphery(_registry) {}

    /// @inheritdoc IMachinePeriphery
    function initialize(bytes calldata data) external virtual override initializer {
        (uint256 _finalizationDelay, bool _whitelistStatus) = abi.decode(data, (uint256, bool));

        AsyncRedeemerStorage storage $ = _getAsyncRedeemerStorage();

        $._finalizationDelay = _finalizationDelay;
        $._nextRequestId = 1;

        __Whitelist_init(_whitelistStatus);
        __ERC721_init("Makina Redeem Queue NFT", "MakinaRedeemQueueNFT");
    }

    /// @inheritdoc IAsyncRedeemer
    function nextRequestId() external view override returns (uint256) {
        return _getAsyncRedeemerStorage()._nextRequestId;
    }

    /// @inheritdoc IAsyncRedeemer
    function lastFinalizedRequestId() external view override returns (uint256) {
        return _getAsyncRedeemerStorage()._lastFinalizedRequestId;
    }

    /// @inheritdoc IAsyncRedeemer
    function finalizationDelay() external view override returns (uint256) {
        return _getAsyncRedeemerStorage()._finalizationDelay;
    }

    /// @inheritdoc IAsyncRedeemer
    function getShares(uint256 requestId) external view override returns (uint256) {
        _requireOwned(requestId);
        return _getAsyncRedeemerStorage()._requests[requestId].shares;
    }

    /// @inheritdoc IAsyncRedeemer
    function getClaimableAssets(uint256 requestId) public view override returns (uint256) {
        _validateFinalizedRequest(requestId);
        return _getAsyncRedeemerStorage()._requests[requestId].assets;
    }

    /// @inheritdoc IAsyncRedeemer
    function previewFinalizeRequests(uint256 upToRequestId) public view override returns (uint256, uint256) {
        AsyncRedeemerStorage storage $ = _getAsyncRedeemerStorage();

        _validateFinalizableRequest(upToRequestId);

        uint256 totalShares;
        uint256 totalAssets;

        for (uint256 i = $._lastFinalizedRequestId + 1; i <= upToRequestId; ++i) {
            IAsyncRedeemer.RedeemRequest memory request = $._requests[i];

            uint256 newSharesValue = IMachine(machine()).convertToAssets(request.shares);
            uint256 newAssets = newSharesValue < request.assets ? newSharesValue : request.assets;

            totalShares += request.shares;
            totalAssets += newAssets;
        }

        return (totalShares, totalAssets);
    }

    /// @inheritdoc IAsyncRedeemer
    function requestRedeem(uint256 shares, address receiver)
        public
        virtual
        override
        nonReentrant
        whitelistCheck
        returns (uint256)
    {
        AsyncRedeemerStorage storage $ = _getAsyncRedeemerStorage();

        uint256 requestId = $._nextRequestId++;

        address _machine = machine();

        $._requests[requestId] =
            IAsyncRedeemer.RedeemRequest(shares, IMachine(_machine).convertToAssets(shares), block.timestamp);

        IERC20(IMachine(_machine).shareToken()).safeTransferFrom(msg.sender, address(this), shares);
        _safeMint(receiver, requestId);

        emit RedeemRequestCreated(uint256(requestId), shares, receiver);

        return requestId;
    }

    /// @inheritdoc IAsyncRedeemer
    function finalizeRequests(uint256 upToRequestId, uint256 minAssets)
        external
        override
        onlyMechanic
        nonReentrant
        returns (uint256, uint256)
    {
        AsyncRedeemerStorage storage $ = _getAsyncRedeemerStorage();

        _validateFinalizableRequest(upToRequestId);

        address _machine = machine();

        uint256 totalShares;
        uint256 totalAssets;

        for (uint256 i = $._lastFinalizedRequestId + 1; i <= upToRequestId; ++i) {
            IAsyncRedeemer.RedeemRequest storage request = $._requests[i];

            uint256 newAssets = IMachine(_machine).convertToAssets(request.shares);
            request.assets = newAssets < request.assets ? newAssets : request.assets;

            totalShares += request.shares;
            totalAssets += request.assets;
        }

        uint256 assets = IMachine(_machine).redeem(totalShares, address(this), minAssets);

        // The conversion from share to asset is linear and rounded down, ensuring that the sum of individual
        // user allocations never exceeds the result of the global redeem.
        // Send any excess assets back to the machine.
        if (assets > totalAssets) {
            IERC20(IMachine(_machine).accountingToken()).safeTransfer(_machine, assets - totalAssets);
        }

        emit RedeemRequestsFinalized($._lastFinalizedRequestId + 1, upToRequestId, totalShares, totalAssets);

        $._lastFinalizedRequestId = upToRequestId;

        return (totalShares, totalAssets);
    }

    /// @inheritdoc IAsyncRedeemer
    function claimAssets(uint256 requestId) external override nonReentrant whitelistCheck returns (uint256) {
        AsyncRedeemerStorage storage $ = _getAsyncRedeemerStorage();

        address receiver = ownerOf(requestId);

        if (msg.sender != receiver) {
            revert IERC721Errors.ERC721IncorrectOwner(msg.sender, requestId, receiver);
        }

        uint256 assets = getClaimableAssets(requestId);
        uint256 shares = $._requests[requestId].shares;

        _burn(requestId);
        delete $._requests[requestId];

        IERC20(IMachine(machine()).accountingToken()).safeTransfer(receiver, assets);

        emit RedeemRequestClaimed(uint256(requestId), shares, assets, receiver);

        return assets;
    }

    /// @inheritdoc IAsyncRedeemer
    function setFinalizationDelay(uint256 newDelay) external override onlyRiskManagerTimelock {
        AsyncRedeemerStorage storage $ = _getAsyncRedeemerStorage();
        emit FinalizationDelayChanged($._finalizationDelay, newDelay);
        $._finalizationDelay = newDelay;
    }

    /// @inheritdoc IWhitelist
    function setWhitelistStatus(bool enabled) external override onlyRiskManager {
        _setWhitelistStatus(enabled);
    }

    /// @inheritdoc IWhitelist
    function setWhitelistedUsers(address[] calldata users, bool whitelisted) external override onlyRiskManager {
        _setWhitelistedUsers(users, whitelisted);
    }

    /// @dev Checks that the request exists, is finalized, and has not yet been claimed.
    function _validateFinalizedRequest(uint256 requestId) internal view {
        _requireOwned(requestId);
        if (requestId > _getAsyncRedeemerStorage()._lastFinalizedRequestId) {
            revert Errors.NotFinalized();
        }
    }

    /// @dev Checks that the request exists and is eligible for finalization.
    function _validateFinalizableRequest(uint256 requestId) internal view {
        AsyncRedeemerStorage storage $ = _getAsyncRedeemerStorage();

        _requireOwned(requestId);

        if (requestId <= $._lastFinalizedRequestId) {
            revert Errors.AlreadyFinalized();
        }
        if (block.timestamp < $._requests[requestId].requestTime + $._finalizationDelay) {
            revert Errors.FinalizationDelayPending();
        }
    }
}
