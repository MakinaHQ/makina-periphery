// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {MachineShare} from "@makina-core/machine/MachineShare.sol";

import {IWatermarkFeeManager} from "src/interfaces/IWatermarkFeeManager.sol";
import {ISecurityModule} from "src/interfaces/ISecurityModule.sol";

import {MachinePeriphery_Integration_Concrete_Test} from "../../machine-periphery/MachinePeriphery.t.sol";

abstract contract WatermarkFeeManager_Integration_Concrete_Test is MachinePeriphery_Integration_Concrete_Test {
    IWatermarkFeeManager public watermarkFeeManager;

    address public securityModuleAddr;

    address public FEE_RECEIVER;

    function setUp() public virtual override {
        MachinePeriphery_Integration_Concrete_Test.setUp();

        FEE_RECEIVER = dao;

        uint256[] memory dummyFeeSplitBps = new uint256[](1);
        dummyFeeSplitBps[0] = 10_000;
        address[] memory dummyFeeSplitReceivers = new address[](1);
        dummyFeeSplitReceivers[0] = FEE_RECEIVER;

        vm.prank(dao);
        watermarkFeeManager = IWatermarkFeeManager(
            hubPeripheryFactory.createFeeManager(
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
            )
        );

        (machine,) = _deployMachine(address(accountingToken), address(0), address(0), address(watermarkFeeManager));
        machineShare = MachineShare(machine.shareToken());

        vm.prank(dao);
        securityModuleAddr = hubPeripheryFactory.createSecurityModule(
            ISecurityModule.SecurityModuleInitParams({
                machineShare: address(machineShare),
                initialCooldownDuration: 0,
                initialMaxSlashableBps: 0,
                initialMinBalanceAfterSlash: 0
            })
        );
    }
}
