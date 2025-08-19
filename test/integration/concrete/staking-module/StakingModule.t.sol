// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {MachineShare} from "@makina-core/machine/MachineShare.sol";

import {IStakingModule} from "src/interfaces/IStakingModule.sol";
import {StakingModule} from "src/staking-module/StakingModule.sol";

import {MachinePeriphery_Integration_Concrete_Test} from "../machine-periphery/MachinePeriphery.t.sol";

abstract contract StakingModule_Integration_Concrete_Test is MachinePeriphery_Integration_Concrete_Test {
    StakingModule public stakingModule;

    address public machineDepositorAddr;

    function setUp() public virtual override {
        MachinePeriphery_Integration_Concrete_Test.setUp();

        machineDepositorAddr = makeAddr("machineDepositor");

        (machine,) = _deployMachine(address(accountingToken), machineDepositorAddr, address(0), address(0));
        machineShare = MachineShare(machine.shareToken());

        vm.prank(dao);
        stakingModule = StakingModule(
            hubPeripheryFactory.createStakingModule(
                IStakingModule.StakingModuleInitParams({
                    machineShare: address(machineShare),
                    initialCooldownDuration: DEFAULT_COOLDOWN_DURATION,
                    initialMaxSlashableBps: DEFAULT_MAX_SLASHABLE_BPS,
                    initialMinBalanceAfterSlash: DEFAULT_MIN_BALANCE_AFTER_SLASH
                })
            )
        );
    }
}
