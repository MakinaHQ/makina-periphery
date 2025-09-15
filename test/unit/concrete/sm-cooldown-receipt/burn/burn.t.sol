// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {IERC721Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {SMCooldownReceipt_Unit_Concrete_Test} from "../SMCooldownReceipt.t.sol";

contract Burn_Unit_Concrete_Test is SMCooldownReceipt_Unit_Concrete_Test {
    function test_Burn_RevertWhen_CallerNotOwner() public {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(this)));
        cooldownReceipt.burn(0);
    }

    function test_Burn() public {
        vm.startPrank(address(securityModule));
        uint256 tokenId = cooldownReceipt.mint(address(this));
        cooldownReceipt.burn(tokenId);

        assertEq(cooldownReceipt.balanceOf(address(this)), 0);

        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, tokenId));
        cooldownReceipt.ownerOf(tokenId);
    }
}
