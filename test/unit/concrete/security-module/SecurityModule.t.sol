// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {DecimalsUtils} from "@makina-core/libraries/DecimalsUtils.sol";
import {Machine} from "@makina-core/machine/Machine.sol";
import {MachineShare} from "@makina-core/machine/MachineShare.sol";

import {Errors, CoreErrors} from "src/libraries/Errors.sol";
import {ISecurityModule} from "src/interfaces/ISecurityModule.sol";
import {SecurityModule} from "src/security-module/SecurityModule.sol";

import {MachinePeriphery_Util_Concrete_Test} from "../machine-periphery/MachinePeriphery.t.sol";
import {Unit_Concrete_Test} from "../UnitConcrete.t.sol";

abstract contract SecurityModule_Util_Concrete_Test is MachinePeriphery_Util_Concrete_Test {
    SecurityModule public securityModule;
    MachineShare public machineShare;

    function setUp() public virtual override {
        Unit_Concrete_Test.setUp();

        (Machine machine,) = _deployMachine(address(accountingToken), address(0), address(0), address(0));
        _machineAddr = address(machine);
        machineShare = MachineShare(machine.shareToken());

        vm.prank(dao);
        securityModule = SecurityModule(
            hubPeripheryFactory.createSecurityModule(
                ISecurityModule.SecurityModuleInitParams({
                    machineShare: address(machineShare),
                    initialCooldownDuration: DEFAULT_COOLDOWN_DURATION,
                    initialMaxSlashableBps: DEFAULT_MAX_SLASHABLE_BPS,
                    initialMinBalanceAfterSlash: DEFAULT_MIN_BALANCE_AFTER_SLASH
                })
            )
        );
    }
}

contract Getters_Setters_SecurityModule_Util_Concrete_Test is SecurityModule_Util_Concrete_Test {
    function test_Getters() public view {
        assertEq(securityModule.decimals(), DecimalsUtils.SHARE_TOKEN_DECIMALS);
        assertEq(securityModule.machine(), _machineAddr);
        assertEq(securityModule.machineShare(), securityModule.machineShare());
        assertEq(securityModule.cooldownDuration(), DEFAULT_COOLDOWN_DURATION);
        assertEq(securityModule.maxSlashableBps(), DEFAULT_MAX_SLASHABLE_BPS);
        assertEq(securityModule.minBalanceAfterSlash(), DEFAULT_MIN_BALANCE_AFTER_SLASH);
        assertEq(securityModule.slashingMode(), false);
        assertEq(securityModule.totalLockedAmount(), 0);
        assertEq(securityModule.maxSlashable(), 0);
    }

    function test_ConvertToShares() public view {
        // should hold when no yield occurred
        assertEq(
            securityModule.convertToShares(10 ** accountingToken.decimals()), 10 ** DecimalsUtils.SHARE_TOKEN_DECIMALS
        );
    }

    function test_ConvertToAssets() public view {
        // should hold when no yield occurred
        assertEq(
            securityModule.convertToAssets(10 ** DecimalsUtils.SHARE_TOKEN_DECIMALS), 10 ** accountingToken.decimals()
        );
    }

    function test_SetMachine_RevertWhen_CallerWithoutRole() public {
        vm.expectRevert(CoreErrors.NotFactory.selector);
        securityModule.setMachine(address(0));
    }

    function test_SetMachine() public {
        vm.expectRevert(Errors.NotImplemented.selector);
        vm.prank(address(hubPeripheryFactory));
        securityModule.setMachine(address(1));
    }

    function test_SetCooldownDuration_RevertWhen_CallerNotRMT() public {
        vm.expectRevert(CoreErrors.UnauthorizedCaller.selector);
        securityModule.setCooldownDuration(0);
    }

    function test_SetCooldownDuration() public {
        uint256 newCooldownDuration = 1 days;

        vm.expectEmit(false, false, false, true, address(securityModule));
        emit ISecurityModule.CooldownDurationChanged(DEFAULT_COOLDOWN_DURATION, newCooldownDuration);

        vm.prank(riskManagerTimelock);
        securityModule.setCooldownDuration(newCooldownDuration);
        assertEq(securityModule.cooldownDuration(), newCooldownDuration);
    }

    function test_SetMaxSlashableBps_RevertWhen_CallerNotRMT() public {
        vm.expectRevert(CoreErrors.UnauthorizedCaller.selector);
        securityModule.setMaxSlashableBps(0);
    }

    function test_SetMaxSlashableBps_RevertWhen_NewValueTooHigh() public {
        vm.expectRevert(Errors.MaxBpsValueExceeded.selector);
        vm.prank(riskManagerTimelock);
        securityModule.setMaxSlashableBps(10001);
    }

    function test_SetMaxSlashableBps() public {
        uint256 newMaxSlashableBps = 6000;

        vm.expectEmit(false, false, false, true, address(securityModule));
        emit ISecurityModule.MaxSlashableBpsChanged(DEFAULT_MAX_SLASHABLE_BPS, newMaxSlashableBps);

        vm.prank(riskManagerTimelock);
        securityModule.setMaxSlashableBps(newMaxSlashableBps);
        assertEq(securityModule.maxSlashableBps(), newMaxSlashableBps);
    }

    function test_SetMinBalanceAfterSlash_RevertWhen_CallerNotRMT() public {
        vm.expectRevert(CoreErrors.UnauthorizedCaller.selector);
        securityModule.setMinBalanceAfterSlash(0);
    }

    function test_SetMinBalanceAfterSlash() public {
        uint256 newMinBalanceAfterSlash = 2e18;

        vm.expectEmit(false, false, false, true, address(securityModule));
        emit ISecurityModule.MinBalanceAfterSlashChanged(DEFAULT_MIN_BALANCE_AFTER_SLASH, newMinBalanceAfterSlash);

        vm.prank(riskManagerTimelock);
        securityModule.setMinBalanceAfterSlash(newMinBalanceAfterSlash);
        assertEq(securityModule.minBalanceAfterSlash(), newMinBalanceAfterSlash);
    }
}
