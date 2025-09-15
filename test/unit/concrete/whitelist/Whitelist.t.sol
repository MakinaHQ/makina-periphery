// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {CoreErrors} from "src/libraries/Errors.sol";
import {IWhitelist} from "src/interfaces/IWhitelist.sol";

import {Unit_Concrete_Test} from "../UnitConcrete.t.sol";

abstract contract Whitelist_Unit_Concrete_Test is Unit_Concrete_Test {
    IWhitelist public whitelist;

    function setUp() public virtual override {}

    function test_Getters() public view {
        assertFalse(whitelist.isWhitelistEnabled());
        assertFalse(whitelist.isWhitelistedUser(address(0)));
    }

    function test_SetWhitelistStatus_RevertGiven_CallerNotRM() public {
        vm.expectRevert(CoreErrors.UnauthorizedCaller.selector);
        whitelist.setWhitelistStatus(true);
    }

    function test_SetWhitelistStatus() public {
        assertFalse(whitelist.isWhitelistEnabled());

        vm.expectEmit(true, false, false, false, address(whitelist));
        emit IWhitelist.WhitelistStatusChanged(true);
        vm.prank(riskManager);
        whitelist.setWhitelistStatus(true);

        assertTrue(whitelist.isWhitelistEnabled());

        vm.expectEmit(true, true, false, false, address(whitelist));
        emit IWhitelist.WhitelistStatusChanged(false);
        vm.prank(riskManager);
        whitelist.setWhitelistStatus(false);

        assertFalse(whitelist.isWhitelistEnabled());
    }

    function test_SetWhitelistedUsers_RevertGiven__CallerNotRM() public {
        vm.expectRevert(CoreErrors.UnauthorizedCaller.selector);
        whitelist.setWhitelistedUsers(new address[](0), true);
    }

    function test_SetWhitelistedUsers() public {
        address user1 = makeAddr("user1");
        address user2 = makeAddr("user2");

        assertFalse(whitelist.isWhitelistedUser(user1));
        assertFalse(whitelist.isWhitelistedUser(user2));

        address[] memory users = new address[](2);
        users[0] = user1;
        users[1] = user2;

        vm.expectEmit(true, true, false, false, address(whitelist));
        emit IWhitelist.UserWhitelistingChanged(user1, true);

        vm.expectEmit(true, true, false, false, address(whitelist));
        emit IWhitelist.UserWhitelistingChanged(user2, true);

        vm.prank(riskManager);
        whitelist.setWhitelistedUsers(users, true);

        assertTrue(whitelist.isWhitelistedUser(user1));
        assertTrue(whitelist.isWhitelistedUser(user2));

        vm.expectEmit(true, true, false, false, address(whitelist));
        emit IWhitelist.UserWhitelistingChanged(user1, false);

        vm.expectEmit(true, true, false, false, address(whitelist));
        emit IWhitelist.UserWhitelistingChanged(user2, false);

        vm.prank(riskManager);
        whitelist.setWhitelistedUsers(users, false);

        assertFalse(whitelist.isWhitelistedUser(user1));
        assertFalse(whitelist.isWhitelistedUser(user2));
    }
}
