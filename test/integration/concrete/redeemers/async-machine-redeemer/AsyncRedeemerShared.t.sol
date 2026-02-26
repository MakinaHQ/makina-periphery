// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {IAsyncRedeemer} from "src/interfaces/IAsyncRedeemer.sol";
import {IWhitelist} from "src/interfaces/IWhitelist.sol";

import {MachinePeriphery_Integration_Concrete_Test} from "../../machine-periphery/MachinePeriphery.t.sol";

abstract contract AsyncRedeemer_Shared_Integration_Concrete_Test is MachinePeriphery_Integration_Concrete_Test {
    IAsyncRedeemer internal asyncRedeemer;

    address internal depositorAddr;

    function setUp() public virtual override {
        MachinePeriphery_Integration_Concrete_Test.setUp();

        depositorAddr = makeAddr("depositor");
    }

    modifier withMachine(address _machine) {
        vm.prank(dao);
        hubPeripheryFactory.setMachine(address(asyncRedeemer), _machine);

        _;
    }

    modifier withWhitelistEnabled() {
        vm.prank(riskManager);
        IWhitelist(address(asyncRedeemer)).setWhitelistStatus(true);

        _;
    }

    modifier withWhitelistedUser(address _user) {
        address[] memory users = new address[](1);
        users[0] = _user;

        vm.prank(riskManager);
        IWhitelist(address(asyncRedeemer)).setWhitelistedUsers(users, true);

        _;
    }

    function _setRecoveryMode() internal {
        vm.prank(securityCouncil);
        machine.setRecoveryMode(true);
    }

    function _previewRedeem(uint256 shares) internal view virtual returns (uint256);
}
