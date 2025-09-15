// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {CoreErrors} from "src/libraries/Errors.sol";

import {WatermarkFeeManager_Integration_Concrete_Test} from "../WatermarkFeeManager.t.sol";

contract DistributeFees_Integration_Concrete_Test is WatermarkFeeManager_Integration_Concrete_Test {
    address public mgmtReceiver1;
    address public mgmtReceiver2;
    address public mgmtReceiver3;

    uint256 public mgmtSplitBps1;
    uint256 public mgmtSplitBps2;
    uint256 public mgmtSplitBps3;

    address public perfReceiver1;
    address public perfReceiver2;

    uint256 public perfSplitBps1;
    uint256 public perfSplitBps2;

    function setUp() public override {
        WatermarkFeeManager_Integration_Concrete_Test.setUp();

        vm.prank(dao);
        hubPeripheryFactory.setMachine(address(watermarkFeeManager), address(machine));

        mgmtReceiver1 = makeAddr("mgmtReceiver1");
        mgmtReceiver2 = makeAddr("mgmtReceiver2");
        mgmtReceiver3 = makeAddr("mgmtReceiver3");

        mgmtSplitBps1 = 5000; // 50%
        mgmtSplitBps2 = 3500; // 35%
        mgmtSplitBps3 = 1500; // 15%

        perfReceiver1 = makeAddr("perfReceiver1");
        perfReceiver2 = makeAddr("perfReceiver2");

        perfSplitBps1 = 7000; // 70%
        perfSplitBps2 = 3000; // 30%

        address[] memory mgmtReceivers = new address[](3);
        mgmtReceivers[0] = mgmtReceiver1;
        mgmtReceivers[1] = mgmtReceiver2;
        mgmtReceivers[2] = mgmtReceiver3;

        uint256[] memory mgmtSplitBps = new uint256[](3);
        mgmtSplitBps[0] = mgmtSplitBps1;
        mgmtSplitBps[1] = mgmtSplitBps2;
        mgmtSplitBps[2] = mgmtSplitBps3;

        address[] memory perfReceivers = new address[](2);
        perfReceivers[0] = perfReceiver1;
        perfReceivers[1] = perfReceiver2;

        uint256[] memory perfSplitBps = new uint256[](2);
        perfSplitBps[0] = perfSplitBps1;
        perfSplitBps[1] = perfSplitBps2;

        vm.startPrank(dao);
        watermarkFeeManager.setMgmtFeeSplit(mgmtReceivers, mgmtSplitBps);
        watermarkFeeManager.setPerfFeeSplit(perfReceivers, perfSplitBps);
        vm.stopPrank();
    }

    function test_RevertWhen_CallerNotMachine() public {
        vm.expectRevert(CoreErrors.NotMachine.selector);
        watermarkFeeManager.distributeFees(0, 0);
    }

    function test_DistributeFees_NoFees() public {
        // Set all fee rates to zero
        vm.startPrank(dao);
        watermarkFeeManager.setSmFeeRatePerSecond(0);
        watermarkFeeManager.setMgmtFeeRatePerSecond(0);
        watermarkFeeManager.setPerfFeeRate(0);
        vm.stopPrank();

        vm.prank(address(machine));
        watermarkFeeManager.distributeFees(0, 0);

        assertEq(machineShare.balanceOf(mgmtReceiver1), 0);
        assertEq(machineShare.balanceOf(mgmtReceiver2), 0);
        assertEq(machineShare.balanceOf(mgmtReceiver3), 0);
        assertEq(machineShare.balanceOf(perfReceiver1), 0);
        assertEq(machineShare.balanceOf(perfReceiver2), 0);
        assertEq(machineShare.balanceOf(address(watermarkFeeManager)), 0);
    }

    function test_DistributeFees_ZeroFixedFee() public {
        uint256 perfFee = 1e18;

        deal(address(machineShare), address(machine), perfFee, true);

        vm.startPrank(address(machine));
        machineShare.approve(address(watermarkFeeManager), perfFee);
        watermarkFeeManager.distributeFees(0, perfFee);

        assertEq(machineShare.balanceOf(mgmtReceiver1), 0);
        assertEq(machineShare.balanceOf(mgmtReceiver2), 0);
        assertEq(machineShare.balanceOf(mgmtReceiver3), 0);
        assertEq(machineShare.balanceOf(perfReceiver1), perfFee * perfSplitBps1 / 10_000);
        assertEq(machineShare.balanceOf(perfReceiver2), perfFee * perfSplitBps2 / 10_000);
        assertEq(machineShare.balanceOf(address(watermarkFeeManager)), 0);
    }

    function test_DistributeFees_WithoutSecurityModule() public {
        uint256 fixedFee = 1e18;
        uint256 perfFee = 2e18;

        deal(address(machineShare), address(machine), fixedFee + perfFee, true);

        vm.startPrank(address(machine));
        machineShare.approve(address(watermarkFeeManager), fixedFee + perfFee);
        watermarkFeeManager.distributeFees(fixedFee, perfFee);

        assertEq(machineShare.balanceOf(mgmtReceiver1), fixedFee * mgmtSplitBps1 / 10_000);
        assertEq(machineShare.balanceOf(mgmtReceiver2), fixedFee * mgmtSplitBps2 / 10_000);
        assertEq(machineShare.balanceOf(mgmtReceiver3), fixedFee * mgmtSplitBps3 / 10_000);
        assertEq(machineShare.balanceOf(perfReceiver1), perfFee * perfSplitBps1 / 10_000);
        assertEq(machineShare.balanceOf(perfReceiver2), perfFee * perfSplitBps2 / 10_000);
        assertEq(machineShare.balanceOf(address(watermarkFeeManager)), 0);
    }

    function test_DistributeFees_WithSecurityModule_ZeroSmFeeRate() public {
        uint256 fixedFee = 1e18;
        uint256 perfFee = 2e18;

        // Set the security module
        vm.prank(address(hubPeripheryFactory));
        watermarkFeeManager.setSecurityModule(securityModuleAddr);

        // Set the SM fee rate to zero
        vm.prank(dao);
        watermarkFeeManager.setSmFeeRatePerSecond(0);

        deal(address(machineShare), address(machine), fixedFee + perfFee, true);

        vm.startPrank(address(machine));
        machineShare.approve(address(watermarkFeeManager), fixedFee + perfFee);
        watermarkFeeManager.distributeFees(fixedFee, perfFee);

        assertEq(machineShare.balanceOf(mgmtReceiver1), fixedFee * mgmtSplitBps1 / 10_000);
        assertEq(machineShare.balanceOf(mgmtReceiver2), fixedFee * mgmtSplitBps2 / 10_000);
        assertEq(machineShare.balanceOf(mgmtReceiver3), fixedFee * mgmtSplitBps3 / 10_000);
        assertEq(machineShare.balanceOf(perfReceiver1), perfFee * perfSplitBps1 / 10_000);
        assertEq(machineShare.balanceOf(perfReceiver2), perfFee * perfSplitBps2 / 10_000);
        assertEq(machineShare.balanceOf(address(watermarkFeeManager)), 0);
    }

    function test_DistributeFees_WithSecurityModule() public {
        uint256 fixedFee = 1e18;
        uint256 perfFee = 2e18;

        // Set the security module
        vm.prank(address(hubPeripheryFactory));
        watermarkFeeManager.setSecurityModule(securityModuleAddr);

        deal(address(machineShare), address(machine), fixedFee + perfFee, true);

        vm.startPrank(address(machine));
        machineShare.approve(address(watermarkFeeManager), fixedFee + perfFee);
        watermarkFeeManager.distributeFees(fixedFee, perfFee);

        uint256 smFee = fixedFee * watermarkFeeManager.smFeeRatePerSecond()
            / (watermarkFeeManager.smFeeRatePerSecond() + watermarkFeeManager.mgmtFeeRatePerSecond());
        uint256 mgmtFee = fixedFee - smFee;

        assertEq(machineShare.balanceOf(securityModuleAddr), smFee);
        assertEq(machineShare.balanceOf(mgmtReceiver1), mgmtFee * mgmtSplitBps1 / 10_000);
        assertEq(machineShare.balanceOf(mgmtReceiver2), mgmtFee * mgmtSplitBps2 / 10_000);
        assertEq(machineShare.balanceOf(mgmtReceiver3), mgmtFee * mgmtSplitBps3 / 10_000);
        assertEq(machineShare.balanceOf(perfReceiver1), perfFee * perfSplitBps1 / 10_000);
        assertEq(machineShare.balanceOf(perfReceiver2), perfFee * perfSplitBps2 / 10_000);
        assertEq(machineShare.balanceOf(address(watermarkFeeManager)), 0);
    }

    function test_DistributeFees_WithSecurityModule_ZeroPerfFee() public {
        uint256 fixedFee = 1e18;

        // Set the security module
        vm.prank(address(hubPeripheryFactory));
        watermarkFeeManager.setSecurityModule(securityModuleAddr);

        deal(address(machineShare), address(machine), fixedFee, true);

        vm.startPrank(address(machine));
        machineShare.approve(address(watermarkFeeManager), fixedFee);
        watermarkFeeManager.distributeFees(fixedFee, 0);

        uint256 smFee = fixedFee * watermarkFeeManager.smFeeRatePerSecond()
            / (watermarkFeeManager.smFeeRatePerSecond() + watermarkFeeManager.mgmtFeeRatePerSecond());
        uint256 mgmtFee = fixedFee - smFee;

        assertEq(machineShare.balanceOf(securityModuleAddr), smFee);
        assertEq(machineShare.balanceOf(mgmtReceiver1), mgmtFee * mgmtSplitBps1 / 10_000);
        assertEq(machineShare.balanceOf(mgmtReceiver2), mgmtFee * mgmtSplitBps2 / 10_000);
        assertEq(machineShare.balanceOf(mgmtReceiver3), mgmtFee * mgmtSplitBps3 / 10_000);
        assertEq(machineShare.balanceOf(perfReceiver1), 0);
        assertEq(machineShare.balanceOf(perfReceiver2), 0);
        assertEq(machineShare.balanceOf(address(watermarkFeeManager)), 0);
    }
}
