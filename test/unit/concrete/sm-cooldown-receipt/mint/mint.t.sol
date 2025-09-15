// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {SMCooldownReceipt_Unit_Concrete_Test} from "../SMCooldownReceipt.t.sol";

contract Mint_Unit_Concrete_Test is SMCooldownReceipt_Unit_Concrete_Test {
    function test_RevertWhen_CallerNotMinter() public {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(this)));
        cooldownReceipt.mint(address(this));
    }

    function test_Mint() public {
        uint256 expectedTokenId = cooldownReceipt.nextTokenId();

        vm.prank(address(securityModule));
        cooldownReceipt.mint(address(this));
        assertEq(cooldownReceipt.balanceOf(address(this)), 1);
        assertEq(cooldownReceipt.ownerOf(expectedTokenId), address(this));
    }
}
