// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {IAccessManaged} from "@openzeppelin/contracts/access/manager/IAccessManaged.sol";

import {IMachinePeriphery} from "src/interfaces/IMachinePeriphery.sol";
import {Errors} from "src/libraries/Errors.sol";

import {HubPeripheryFactory_Integration_Concrete_Test} from "../HubPeripheryFactory.t.sol";

contract SetMachine_Integration_Concrete_Test is HubPeripheryFactory_Integration_Concrete_Test {
    function test_RevertWhen_CallerWithoutRole() public {
        vm.expectRevert(abi.encodeWithSelector(IAccessManaged.AccessManagedUnauthorized.selector, address(this)));
        hubPeripheryFactory.setMachine(address(0), address(0));
    }

    function test_RevertWhen_InvalidMachinePeriphery() public {
        vm.expectRevert(Errors.InvalidMachinePeriphery.selector);
        vm.prank(dao);
        hubPeripheryFactory.setMachine(address(0), address(0));
    }

    function test_SetMachine() public {
        vm.prank(dao);
        address machinePeriphery = hubPeripheryFactory.createDepositor(DUMMY_MANAGER_IMPLEM_ID, "");

        address machine = makeAddr("machine");

        vm.prank(dao);
        hubPeripheryFactory.setMachine(machinePeriphery, machine);

        assertEq(IMachinePeriphery(machinePeriphery).machine(), machine);
    }
}
