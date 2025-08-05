// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {DecimalsUtils} from "@makina-core/libraries/DecimalsUtils.sol";
import {Machine} from "@makina-core/machine/Machine.sol";
import {MachineShare} from "@makina-core/machine/MachineShare.sol";

import {Errors, CoreErrors} from "src/libraries/Errors.sol";
import {IStakingModule} from "src/interfaces/IStakingModule.sol";
import {StakingModule} from "src/staking-module/StakingModule.sol";

import {MachinePeriphery_Util_Concrete_Test} from "../machine-periphery/MachinePeriphery.t.sol";
import {Unit_Concrete_Test} from "../UnitConcrete.t.sol";

abstract contract StakingModule_Util_Concrete_Test is MachinePeriphery_Util_Concrete_Test {
    StakingModule public stakingModule;
    MachineShare public machineShare;

    function setUp() public virtual override {
        Unit_Concrete_Test.setUp();

        (Machine machine,) = _deployMachine(address(accountingToken), address(0), address(0), address(0));
        _machineAddr = address(machine);
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

contract Getters_Setters_StakingModule_Util_Concrete_Test is StakingModule_Util_Concrete_Test {
    function test_Getters() public view {
        assertEq(stakingModule.decimals(), DecimalsUtils.SHARE_TOKEN_DECIMALS);
        assertEq(stakingModule.machine(), _machineAddr);
        assertEq(stakingModule.machineShare(), stakingModule.machineShare());
        assertEq(stakingModule.cooldownDuration(), DEFAULT_COOLDOWN_DURATION);
        assertEq(stakingModule.maxSlashableBps(), DEFAULT_MAX_SLASHABLE_BPS);
        assertEq(stakingModule.minBalanceAfterSlash(), DEFAULT_MIN_BALANCE_AFTER_SLASH);
        assertEq(stakingModule.slashingMode(), false);
        assertEq(stakingModule.totalStakedAmount(), 0);
        assertEq(stakingModule.maxSlashable(), 0);
    }

    function test_ConvertToShares() public view {
        // should hold when no yield occurred
        assertEq(
            stakingModule.convertToShares(10 ** accountingToken.decimals()), 10 ** DecimalsUtils.SHARE_TOKEN_DECIMALS
        );
    }

    function test_ConvertToAssets() public view {
        // should hold when no yield occurred
        assertEq(
            stakingModule.convertToAssets(10 ** DecimalsUtils.SHARE_TOKEN_DECIMALS), 10 ** accountingToken.decimals()
        );
    }

    function test_SetMachine_RevertWhen_CallerWithoutRole() public {
        vm.expectRevert(CoreErrors.NotFactory.selector);
        stakingModule.setMachine(address(0));
    }

    function test_SetMachine() public {
        vm.expectRevert(Errors.NotImplemented.selector);
        vm.prank(address(hubPeripheryFactory));
        stakingModule.setMachine(address(1));
    }

    function test_SetCooldownDuration_RevertWhen_CallerNotRM() public {
        vm.expectRevert(CoreErrors.UnauthorizedCaller.selector);
        stakingModule.setCooldownDuration(0);
    }

    function test_SetCooldownDuration() public {
        uint256 newCooldownDuration = 1 days;

        vm.expectEmit(false, false, false, true, address(stakingModule));
        emit IStakingModule.CooldownDurationChanged(DEFAULT_COOLDOWN_DURATION, newCooldownDuration);

        vm.prank(riskManager);
        stakingModule.setCooldownDuration(newCooldownDuration);
        assertEq(stakingModule.cooldownDuration(), newCooldownDuration);
    }

    function test_SetMaxSlashableBps_RevertWhen_CallerNotRM() public {
        vm.expectRevert(CoreErrors.UnauthorizedCaller.selector);
        stakingModule.setMaxSlashableBps(0);
    }

    function test_SetMaxSlashableBps_RevertWhen_NewValueTooHigh() public {
        vm.expectRevert(Errors.MaxBpsValueExceeded.selector);
        vm.prank(riskManager);
        stakingModule.setMaxSlashableBps(10001);
    }

    function test_SetMaxSlashableBps() public {
        uint256 newMaxSlashableBps = 6000;

        vm.expectEmit(false, false, false, true, address(stakingModule));
        emit IStakingModule.MaxSlashableBpsChanged(DEFAULT_MAX_SLASHABLE_BPS, newMaxSlashableBps);

        vm.prank(riskManager);
        stakingModule.setMaxSlashableBps(newMaxSlashableBps);
        assertEq(stakingModule.maxSlashableBps(), newMaxSlashableBps);
    }

    function test_SetMinBalanceAfterSlash_RevertWhen_CallerNotRM() public {
        vm.expectRevert(CoreErrors.UnauthorizedCaller.selector);
        stakingModule.setMinBalanceAfterSlash(0);
    }

    function test_SetMinBalanceAfterSlash() public {
        uint256 newMinBalanceAfterSlash = 2e18;

        vm.expectEmit(false, false, false, true, address(stakingModule));
        emit IStakingModule.MinBalanceAfterSlashChanged(DEFAULT_MIN_BALANCE_AFTER_SLASH, newMinBalanceAfterSlash);

        vm.prank(riskManager);
        stakingModule.setMinBalanceAfterSlash(newMinBalanceAfterSlash);
        assertEq(stakingModule.minBalanceAfterSlash(), newMinBalanceAfterSlash);
    }
}
