// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {IMachine} from "@makina-core/interfaces/IMachine.sol";

import {Errors, CoreErrors} from "src/libraries/Errors.sol";
import {IWatermarkFeeManager} from "src/interfaces/IWatermarkFeeManager.sol";
import {MockMachinePeriphery} from "test/mocks/MockMachinePeriphery.sol";

import {WatermarkFeeManager_Integration_Concrete_Test} from "../WatermarkFeeManager.t.sol";

contract SetStakingModule_Integration_Concrete_Test is WatermarkFeeManager_Integration_Concrete_Test {
    function test_RevertWhen_CallerNotFactory() public {
        vm.expectRevert(CoreErrors.NotFactory.selector);
        watermarkFeeManager.setStakingModule(address(0));
    }

    function test_RevertGiven_MachineNotSet() public {
        vm.expectRevert(Errors.MachineNotSet.selector);
        vm.prank(address(hubPeripheryFactory));
        watermarkFeeManager.setStakingModule(address(stakingModuleAddr));
    }

    function test_RevertGiven_StakingModuleAlreadySet() public {
        vm.prank(dao);
        hubPeripheryFactory.setMachine(address(watermarkFeeManager), address(machine));

        vm.startPrank(address(hubPeripheryFactory));
        watermarkFeeManager.setStakingModule(address(stakingModuleAddr));

        vm.expectRevert(Errors.StakingModuleAlreadySet.selector);
        watermarkFeeManager.setStakingModule(address(stakingModuleAddr));
    }

    function test_RevertGiven_InvalidStakingModule() public {
        vm.prank(dao);
        hubPeripheryFactory.setMachine(address(watermarkFeeManager), address(machine));

        MockMachinePeriphery mockStakingModule = new MockMachinePeriphery();

        vm.startPrank(address(hubPeripheryFactory));
        vm.expectRevert(Errors.InvalidStakingModule.selector);
        watermarkFeeManager.setStakingModule(address(mockStakingModule));
    }

    function test_SetStakingModule() public {
        vm.prank(dao);
        hubPeripheryFactory.setMachine(address(watermarkFeeManager), address(machine));

        vm.expectEmit(true, false, false, false, address(watermarkFeeManager));
        emit IWatermarkFeeManager.StakingModuleSet(stakingModuleAddr);
        vm.prank(address(hubPeripheryFactory));
        watermarkFeeManager.setStakingModule(stakingModuleAddr);

        assertEq(watermarkFeeManager.stakingModule(), stakingModuleAddr);
    }
}
