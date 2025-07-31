/// SPDX-License-Identifier: UNLICENSED
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
import {IAsyncMachineRedeemer} from "../interfaces/IAsyncMachineRedeemer.sol";
import {IMachinePeriphery} from "../interfaces/IMachinePeriphery.sol";

contract AsyncMachineRedeemer is
    ERC721Upgradeable,
    ReentrancyGuardUpgradeable,
    MachinePeriphery,
    IAsyncMachineRedeemer
{
    using Math for uint256;
    using SafeERC20 for IERC20;

    /// @custom:storage-location erc7201:makina.storage.AsyncMachineRedeemer
    struct AsyncMachineRedeemerStorage {
        uint256 _nextRequestId;
        uint256 _lastFinalizedRequestId;
        mapping(uint256 requestId => IAsyncMachineRedeemer.RedeemRequest request) _requests;
    }

    // keccak256(abi.encode(uint256(keccak256("makina.storage.AsyncMachineRedeemer")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant AsyncMachineRedeemerStorageLocation =
        0x834d0b78c6ccd5774fe62696b39cee631e0dfdc36e42b36ad17cbc45095ebe00;

    function _getAsyncMachineRedeemerStorage() private pure returns (AsyncMachineRedeemerStorage storage $) {
        assembly {
            $.slot := AsyncMachineRedeemerStorageLocation
        }
    }

    constructor(address _registry) MachinePeriphery(_registry) {
        _disableInitializers();
    }

    /// @inheritdoc IMachinePeriphery
    function initialize(bytes calldata) external virtual override initializer {
        __ERC721_init("Makina Redeem Queue NFT", "MakinaRedeemQueueNFT");
        _getAsyncMachineRedeemerStorage()._nextRequestId = 1;
    }

    /// @inheritdoc IAsyncMachineRedeemer
    function nextRequestId() external view override returns (uint256) {
        return _getAsyncMachineRedeemerStorage()._nextRequestId;
    }

    /// @inheritdoc IAsyncMachineRedeemer
    function lastFinalizedRequestId() external view override returns (uint256) {
        return _getAsyncMachineRedeemerStorage()._lastFinalizedRequestId;
    }

    /// @inheritdoc IAsyncMachineRedeemer
    function getShares(uint256 requestId) external view override returns (uint256) {
        _requireOwned(requestId);
        return _getAsyncMachineRedeemerStorage()._requests[requestId].shares;
    }

    /// @inheritdoc IAsyncMachineRedeemer
    function getClaimableAssets(uint256 requestId) public view override returns (uint256) {
        _validateFinalizedRequest(requestId);
        return _getAsyncMachineRedeemerStorage()._requests[requestId].assets;
    }

    /// @inheritdoc IAsyncMachineRedeemer
    function previewFinalizeRequests(uint256 upToRequestId) public view override returns (uint256, uint256) {
        AsyncMachineRedeemerStorage storage $ = _getAsyncMachineRedeemerStorage();

        _validateUnfinalizedRequest(upToRequestId);

        uint256 totalShares;
        uint256 totalAssets;

        for (uint256 i = $._lastFinalizedRequestId + 1; i <= upToRequestId; ++i) {
            IAsyncMachineRedeemer.RedeemRequest memory request = $._requests[i];

            uint256 newSharesValue = IMachine(machine()).convertToAssets(request.shares);
            uint256 newAssets = newSharesValue < request.assets ? newSharesValue : request.assets;

            totalShares += request.shares;
            totalAssets += newAssets;
        }

        return (totalShares, totalAssets);
    }

    /// @inheritdoc IAsyncMachineRedeemer
    function requestRedeem(uint256 shares, address recipient) public virtual override nonReentrant returns (uint256) {
        AsyncMachineRedeemerStorage storage $ = _getAsyncMachineRedeemerStorage();

        uint256 requestId = $._nextRequestId++;

        address _machine = machine();

        $._requests[requestId] =
            IAsyncMachineRedeemer.RedeemRequest(shares, IMachine(_machine).convertToAssets(shares), true);

        IERC20(IMachine(_machine).shareToken()).safeTransferFrom(msg.sender, address(this), shares);
        _safeMint(recipient, requestId);

        emit RedeemRequestCreated(uint256(requestId), shares, recipient);

        return requestId;
    }

    /// @inheritdoc IAsyncMachineRedeemer
    function finalizeRequests(uint256 upToRequestId, uint256 minAssets)
        external
        override
        onlyOperator
        nonReentrant
        returns (uint256, uint256)
    {
        AsyncMachineRedeemerStorage storage $ = _getAsyncMachineRedeemerStorage();

        _validateUnfinalizedRequest(upToRequestId);

        address _machine = machine();

        uint256 totalShares;
        uint256 totalAssets;

        for (uint256 i = $._lastFinalizedRequestId + 1; i <= upToRequestId; ++i) {
            IAsyncMachineRedeemer.RedeemRequest storage request = $._requests[i];

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

    /// @inheritdoc IAsyncMachineRedeemer
    function claimAssets(uint256 requestId) external override nonReentrant returns (uint256) {
        AsyncMachineRedeemerStorage storage $ = _getAsyncMachineRedeemerStorage();

        address recipient = ownerOf(requestId);

        if (msg.sender != recipient) {
            revert IERC721Errors.ERC721IncorrectOwner(msg.sender, requestId, recipient);
        }

        uint256 assets = getClaimableAssets(requestId);
        uint256 shares = $._requests[requestId].shares;

        _burn(requestId);
        delete $._requests[requestId];

        IERC20(IMachine(machine()).accountingToken()).safeTransfer(recipient, assets);

        emit RedeemRequestClaimed(uint256(requestId), shares, assets, recipient);

        return assets;
    }

    /// @dev Checks that the request exists, is finalized, and has not yet been claimed.
    function _validateFinalizedRequest(uint256 requestId) internal view {
        _requireOwned(requestId);
        if (requestId > _getAsyncMachineRedeemerStorage()._lastFinalizedRequestId) {
            revert Errors.NotFinalized();
        }
    }

    /// @dev Checks that the request exists and is not finalized.
    function _validateUnfinalizedRequest(uint256 requestId) internal view {
        _requireOwned(requestId);
        if (requestId <= _getAsyncMachineRedeemerStorage()._lastFinalizedRequestId) {
            revert Errors.AlreadyFinalized();
        }
    }
}
