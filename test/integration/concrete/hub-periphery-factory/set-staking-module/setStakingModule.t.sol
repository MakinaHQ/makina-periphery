// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {IAccessManaged} from "@openzeppelin/contracts/access/manager/IAccessManaged.sol";

import {Machine} from "@makina-core/machine/Machine.sol";

import {IStakingModule} from "src/interfaces/IStakingModule.sol";
import {IStakingModuleReference} from "src/interfaces/IStakingModuleReference.sol";
import {IWatermarkFeeManager} from "src/interfaces/IWatermarkFeeManager.sol";
import {Errors} from "src/libraries/Errors.sol";

import {HubPeripheryFactory_Integration_Concrete_Test} from "../HubPeripheryFactory.t.sol";

contract SetStakingModule_Integration_Concrete_Test is HubPeripheryFactory_Integration_Concrete_Test {
    function test_RevertWhen_CallerWithoutRole() public {
        vm.expectRevert(abi.encodeWithSelector(IAccessManaged.AccessManagedUnauthorized.selector, address(this)));
        hubPeripheryFactory.setStakingModule(address(0), address(0));
    }

    function test_RevertWhen_NotFeeManager() public {
        vm.expectRevert(Errors.NotFeeManager.selector);
        vm.prank(dao);
        hubPeripheryFactory.setStakingModule(address(0), address(0));
    }

    function test_RevertWhen_NotStakingModule() public {
        vm.startPrank(dao);

        address feeManager = hubPeripheryFactory.createFeeManager(DUMMY_MANAGER_IMPLEM_ID, "");
        vm.expectRevert(Errors.NotStakingModule.selector);

        hubPeripheryFactory.setStakingModule(feeManager, address(0));
    }

    function test_SetStakingModule() public {
        (Machine machine,) = _deployMachine(address(accountingToken), address(0), address(0), address(0));

        uint256[] memory dummyFeeSplitBps = new uint256[](1);
        dummyFeeSplitBps[0] = 10_000;
        address[] memory dummyFeeSplitReceivers = new address[](1);
        dummyFeeSplitReceivers[0] = dao;

        vm.startPrank(dao);

        address feeManager = hubPeripheryFactory.createFeeManager(
            WATERMARK_FEE_MANAGER_IMPLEM_ID,
            abi.encode(
                IWatermarkFeeManager.WatermarkFeeManagerInitParams({
                    initialMgmtFeeRatePerSecond: DEFAULT_WATERMARK_FEE_MANAGER_MGMT_FEE_RATE_PER_SECOND,
                    initialSmFeeRatePerSecond: DEFAULT_WATERMARK_FEE_MANAGER_SM_FEE_RATE_PER_SECOND,
                    initialPerfFeeRate: DEFAULT_WATERMARK_FEE_MANAGER_PERF_FEE_RATE,
                    initialMgmtFeeSplitBps: dummyFeeSplitBps,
                    initialMgmtFeeReceivers: dummyFeeSplitReceivers,
                    initialPerfFeeSplitBps: dummyFeeSplitBps,
                    initialPerfFeeReceivers: dummyFeeSplitReceivers
                })
            )
        );
        hubPeripheryFactory.setMachine(feeManager, address(machine));

        address machineShare = machine.shareToken();

        address stakingModule = hubPeripheryFactory.createStakingModule(
            IStakingModule.StakingModuleInitParams({
                machineShare: machineShare,
                initialCooldownDuration: 0,
                initialMaxSlashableBps: 0,
                initialMinBalanceAfterSlash: 0
            })
        );

        hubPeripheryFactory.setStakingModule(feeManager, stakingModule);

        assertEq(IStakingModuleReference(feeManager).stakingModule(), stakingModule);
    }
}
