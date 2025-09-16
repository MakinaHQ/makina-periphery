// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {Errors, CoreErrors} from "src/libraries/Errors.sol";
import {IWatermarkFeeManager} from "src/interfaces/IWatermarkFeeManager.sol";
import {MockMachinePeriphery} from "test/mocks/MockMachinePeriphery.sol";

import {WatermarkFeeManager_Integration_Concrete_Test} from "../WatermarkFeeManager.t.sol";

contract SetSecurityModule_Integration_Concrete_Test is WatermarkFeeManager_Integration_Concrete_Test {
    function test_RevertWhen_CallerNotFactory() public {
        vm.expectRevert(CoreErrors.NotFactory.selector);
        watermarkFeeManager.setSecurityModule(address(0));
    }

    function test_RevertGiven_MachineNotSet() public {
        vm.expectRevert(Errors.MachineNotSet.selector);
        vm.prank(address(hubPeripheryFactory));
        watermarkFeeManager.setSecurityModule(address(securityModuleAddr));
    }

    function test_RevertGiven_SecurityModuleAlreadySet() public {
        vm.prank(dao);
        hubPeripheryFactory.setMachine(address(watermarkFeeManager), address(machine));

        vm.startPrank(address(hubPeripheryFactory));
        watermarkFeeManager.setSecurityModule(address(securityModuleAddr));

        vm.expectRevert(Errors.SecurityModuleAlreadySet.selector);
        watermarkFeeManager.setSecurityModule(address(securityModuleAddr));
    }

    function test_RevertGiven_InvalidSecurityModule() public {
        vm.prank(dao);
        hubPeripheryFactory.setMachine(address(watermarkFeeManager), address(machine));

        MockMachinePeriphery mockSecurityModule = new MockMachinePeriphery();

        vm.startPrank(address(hubPeripheryFactory));
        vm.expectRevert(Errors.InvalidSecurityModule.selector);
        watermarkFeeManager.setSecurityModule(address(mockSecurityModule));
    }

    function test_SetSecurityModule() public {
        vm.prank(dao);
        hubPeripheryFactory.setMachine(address(watermarkFeeManager), address(machine));

        vm.expectEmit(true, false, false, false, address(watermarkFeeManager));
        emit IWatermarkFeeManager.SecurityModuleSet(securityModuleAddr);
        vm.prank(address(hubPeripheryFactory));
        watermarkFeeManager.setSecurityModule(securityModuleAddr);

        assertEq(watermarkFeeManager.securityModule(), securityModuleAddr);
    }
}
