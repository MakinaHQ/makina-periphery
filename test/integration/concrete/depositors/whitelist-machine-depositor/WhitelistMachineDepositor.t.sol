// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {MachineShare} from "@makina-core/machine/MachineShare.sol";

import {WhitelistMachineDepositor} from "src/depositors/WhitelistMachineDepositor.sol";

import {MachinePeriphery_Integration_Concrete_Test} from "../../machine-periphery/MachinePeriphery.t.sol";

contract WhitelistMachineDepositor_Integration_Concrete_Test is MachinePeriphery_Integration_Concrete_Test {
    WhitelistMachineDepositor public whitelistMachineDepositor;

    function setUp() public virtual override {
        MachinePeriphery_Integration_Concrete_Test.setUp();

        vm.prank(dao);
        whitelistMachineDepositor = WhitelistMachineDepositor(
            hubPeripheryFactory.createMachineDepositor(WHITELISTED_DEPOSIT_MANAGER_IMPLEM_ID, "")
        );

        (machine,) =
            _deployMachine(address(accountingToken), address(whitelistMachineDepositor), address(0), address(0));
        machineShare = MachineShare(machine.shareToken());
    }

    modifier withMachine(address _machine) {
        vm.prank(dao);
        hubPeripheryFactory.setMachine(address(whitelistMachineDepositor), _machine);

        _;
    }

    modifier withWhitelistedUser(address _user) {
        address[] memory users = new address[](1);
        users[0] = _user;

        vm.prank(dao);
        whitelistMachineDepositor.setWhitelistedUsers(users, true);

        _;
    }
}
