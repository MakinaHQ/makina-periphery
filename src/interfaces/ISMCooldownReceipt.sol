// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ISMCooldownReceipt is IERC721 {
    /// @notice ID of the next token to be minted.
    function nextTokenId() external view returns (uint256);

    /// @notice Mints a new cooldown receipt NFT to the specified address.
    /// @param to The receiver of the minted NFT.
    /// @return tokenId The ID of the minted NFT.
    function mint(address to) external returns (uint256 tokenId);

    /// @notice Burns the specified cooldown receipt NFT.
    /// @param tokenId The ID of the NFT to burn.
    function burn(uint256 tokenId) external;
}
