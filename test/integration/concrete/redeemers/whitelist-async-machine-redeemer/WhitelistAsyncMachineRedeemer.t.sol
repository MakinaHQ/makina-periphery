// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {WhitelistAsyncMachineRedeemer} from "src/redeemers/WhitelistAsyncMachineRedeemer.sol";
import {MachineShare} from "@makina-core/machine/MachineShare.sol";

import {MachinePeriphery_Integration_Concrete_Test} from "../../machine-periphery/MachinePeriphery.t.sol";

contract WhitelistAsyncMachineRedeemer_Integration_Concrete_Test is MachinePeriphery_Integration_Concrete_Test {
    WhitelistAsyncMachineRedeemer public whitelistAsyncMachineRedeemer;

    address public machineDepositorAddr;

    function setUp() public virtual override {
        MachinePeriphery_Integration_Concrete_Test.setUp();

        vm.prank(dao);
        whitelistAsyncMachineRedeemer = WhitelistAsyncMachineRedeemer(
            hubPeripheryFactory.createMachineRedeemer(WHITELISTED_ASYNC_REDEEM_MANAGER_IMPLEM_ID, "")
        );

        machineDepositorAddr = makeAddr("machineDepositor");

        (machine,) = _deployMachine(
            address(accountingToken), machineDepositorAddr, address(whitelistAsyncMachineRedeemer), address(0)
        );
        machineShare = MachineShare(machine.shareToken());
    }

    modifier withMachine(address _machine) {
        vm.prank(address(hubPeripheryFactory));
        whitelistAsyncMachineRedeemer.setMachine(_machine);

        _;
    }

    modifier withWhitelistedUser(address _user) {
        address[] memory users = new address[](1);
        users[0] = _user;

        vm.prank(dao);
        whitelistAsyncMachineRedeemer.setWhitelistedUsers(users, true);

        _;
    }
}
