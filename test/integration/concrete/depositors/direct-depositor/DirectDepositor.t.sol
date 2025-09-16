// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {MachineShare} from "@makina-core/machine/MachineShare.sol";

import {DirectDepositor} from "src/depositors/DirectDepositor.sol";

import {MachinePeriphery_Integration_Concrete_Test} from "../../machine-periphery/MachinePeriphery.t.sol";

contract DirectDepositor_Integration_Concrete_Test is MachinePeriphery_Integration_Concrete_Test {
    DirectDepositor public directDepositor;

    function setUp() public virtual override {
        MachinePeriphery_Integration_Concrete_Test.setUp();

        vm.prank(dao);
        directDepositor = DirectDepositor(
            hubPeripheryFactory.createDepositor(
                DIRECT_DEPOSITOR_IMPLEM_ID, abi.encode(DEFAULT_INITIAL_WHITELIST_STATUS)
            )
        );

        (machine,) = _deployMachine(address(accountingToken), address(directDepositor), address(0), address(0));
        machineShare = MachineShare(machine.shareToken());
    }

    modifier withMachine(address _machine) {
        vm.prank(dao);
        hubPeripheryFactory.setMachine(address(directDepositor), _machine);

        _;
    }

    modifier withWhitelistEnabled() {
        vm.prank(riskManager);
        directDepositor.setWhitelistStatus(true);

        _;
    }

    modifier withWhitelistedUser(address _user) {
        address[] memory users = new address[](1);
        users[0] = _user;

        vm.prank(riskManager);
        directDepositor.setWhitelistedUsers(users, true);

        _;
    }
}
