// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IMachinePeriphery} from "./IMachinePeriphery.sol";

interface IAsyncRedeemer is IMachinePeriphery {
    event FinalizationDelayChanged(uint256 indexed oldDelay, uint256 indexed newDelay);
    event RedeemRequestCreated(uint256 indexed requestId, uint256 shares, address indexed receiver);
    event RedeemRequestClaimed(uint256 indexed requestId, uint256 shares, uint256 assets, address indexed receiver);
    event RedeemRequestsFinalized(
        uint256 indexed fromRequestId, uint256 indexed toRequestId, uint256 totalShares, uint256 totalAssets
    );

    struct RedeemRequest {
        uint256 shares;
        uint256 assets;
        uint256 requestTime;
    }

    /// @notice ID of the next redeem request to be created.
    function nextRequestId() external view returns (uint256);

    /// @notice ID of the last finalized redeem request.
    function lastFinalizedRequestId() external view returns (uint256);

    /// @notice Minimum time (in seconds) to be elapsed between request submission and finalization.
    function finalizationDelay() external view returns (uint256);

    /// @notice Request ID => Shares
    function getShares(uint256 requestId) external view returns (uint256);

    /// @notice Request ID => Claimable Assets
    /// @dev Reverts if the request is not finalized.
    function getClaimableAssets(uint256 requestId) external view returns (uint256);

    /// @notice Returns the total shares and curreent expected assets for a batch of unfinalized requests up to given request ID.
    /// @param upToRequestId The request ID up to which to calculate the total shares and assets.
    /// @return totalShares The total shares for the batch of requests.
    /// @return totalAssets The current total assets for the batch of requests.
    function previewFinalizeRequests(uint256 upToRequestId) external view returns (uint256, uint256);

    /// @notice Creates a redeem request and issues an associated NFT to the receiver.
    /// @param shares The amount of shares to redeem.
    /// @param receiver The receiver of the receipt NFT.
    /// @return requestId The ID of the redeem request.
    function requestRedeem(uint256 shares, address receiver) external returns (uint256);

    /// @notice Finalizes redeem requests up to a given request ID.
    /// @dev Can only be called by the operator of the associated machine.
    /// @param upToRequestId The request ID up to which to finalize requests.
    /// @param minAssets The minimum amount of assets that must be available for the requests to be finalized.
    function finalizeRequests(uint256 upToRequestId, uint256 minAssets) external returns (uint256, uint256);

    /// @notice Claims the assets associated with a finalized redeem request and burns the associated NFT.
    /// @param requestId the ID of the redeem request and associated NFT.
    function claimAssets(uint256 requestId) external returns (uint256);

    /// @notice Sets the finalization delay for redeem requests.
    /// @param newDelay The new finalization delay in seconds.
    function setFinalizationDelay(uint256 newDelay) external;
}
