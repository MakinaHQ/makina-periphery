// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {MachineShare} from "@makina-core/machine/MachineShare.sol";

import {IAsyncRedeemer} from "src/interfaces/IAsyncRedeemer.sol";
import {IWhitelist} from "src/interfaces/IWhitelist.sol";

import {Constants} from "../../../../utils/Constants.sol";

import {MachinePeriphery_Integration_Concrete_Test} from "../../machine-periphery/MachinePeriphery.t.sol";

contract AsyncRedeemer_Integration_Concrete_Test is MachinePeriphery_Integration_Concrete_Test {
    IAsyncRedeemer public asyncRedeemer;

    address public depositorAddr;

    function setUp() public virtual override {
        MachinePeriphery_Integration_Concrete_Test.setUp();

        vm.prank(dao);
        asyncRedeemer = IAsyncRedeemer(
            hubPeripheryFactory.createRedeemer(
                ASYNC_REDEEMER_IMPLEM_ID, abi.encode(DEFAULT_FINALIZATION_DELAY, DEFAULT_INITIAL_WHITELIST_STATUS)
            )
        );

        depositorAddr = makeAddr("depositor");

        (machine,) = _deployMachine(address(accountingToken), depositorAddr, address(asyncRedeemer), address(0));
        machineShare = MachineShare(machine.shareToken());
    }

    modifier withMachine(address _machine) {
        vm.prank(dao);
        hubPeripheryFactory.setMachine(address(asyncRedeemer), _machine);

        _;
    }

    modifier withWhitelistEnabled() {
        vm.prank(dao);
        IWhitelist(address(asyncRedeemer)).setWhitelistStatus(true);

        _;
    }

    modifier withWhitelistedUser(address _user) {
        address[] memory users = new address[](1);
        users[0] = _user;

        vm.prank(dao);
        IWhitelist(address(asyncRedeemer)).setWhitelistedUsers(users, true);

        _;
    }

    function _setRecoveryMode() internal {
        vm.prank(securityCouncil);
        machine.setRecoveryMode(true);
    }
}
