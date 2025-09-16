// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable2Step, Ownable} from "@openzeppelin/contracts/access/Ownable2Step.sol";

import {ISMCooldownReceipt} from "../interfaces/ISMCooldownReceipt.sol";

contract SMCooldownReceipt is ERC721, Ownable2Step, ISMCooldownReceipt {
    /// @inheritdoc ISMCooldownReceipt
    uint256 public nextTokenId;

    constructor(address _initialMinter)
        ERC721("Makina Security Module Cooldown NFT", "MakinaSMCooldownNFT")
        Ownable(_initialMinter)
    {
        nextTokenId = 1;
    }

    /// @inheritdoc ISMCooldownReceipt
    function mint(address to) external onlyOwner returns (uint256) {
        uint256 tokenId = nextTokenId++;
        _safeMint(to, tokenId);
        return tokenId;
    }

    /// @inheritdoc ISMCooldownReceipt
    function burn(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
    }
}
