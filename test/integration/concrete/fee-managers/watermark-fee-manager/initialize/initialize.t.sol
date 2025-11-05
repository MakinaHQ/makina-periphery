// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";

import {Errors} from "src/libraries/Errors.sol";
import {IMachinePeriphery} from "src/interfaces/IMachinePeriphery.sol";
import {IWatermarkFeeManager} from "src/interfaces/IWatermarkFeeManager.sol";

import {WatermarkFeeManager_Integration_Concrete_Test} from "../WatermarkFeeManager.t.sol";

contract Initialize_Integration_Concrete_Test is WatermarkFeeManager_Integration_Concrete_Test {
    function test_RevertWhen_ProvidedMaxFeeRateValueExceeded() public {
        IWatermarkFeeManager.WatermarkFeeManagerInitParams memory initParams = _getWatermarkFeeManagerInitParams();

        initParams.initialMgmtFeeRatePerSecond = 1e18 + 1;

        vm.expectRevert(Errors.MaxFeeRateValueExceeded.selector);
        new BeaconProxy(
            address(watermarkFeeManagerBeacon), abi.encodeCall(IMachinePeriphery.initialize, (abi.encode(initParams)))
        );

        initParams.initialMgmtFeeRatePerSecond = 1e18;
        initParams.initialSmFeeRatePerSecond = 1e18 + 1;

        vm.expectRevert(Errors.MaxFeeRateValueExceeded.selector);
        new BeaconProxy(
            address(watermarkFeeManagerBeacon), abi.encodeCall(IMachinePeriphery.initialize, (abi.encode(initParams)))
        );

        initParams.initialSmFeeRatePerSecond = 1e18;
        initParams.initialPerfFeeRate = 1e18 + 1;

        vm.expectRevert(Errors.MaxFeeRateValueExceeded.selector);
        new BeaconProxy(
            address(watermarkFeeManagerBeacon), abi.encodeCall(IMachinePeriphery.initialize, (abi.encode(initParams)))
        );
    }

    function test_RevertWhen_InvalidMgmtFeeSplit() public {
        IWatermarkFeeManager.WatermarkFeeManagerInitParams memory initParams = _getWatermarkFeeManagerInitParams();

        initParams.initialMgmtFeeReceivers = new address[](0);
        initParams.initialMgmtFeeSplitBps = new uint256[](0);

        vm.startPrank(dao);

        // Empty fee split
        vm.expectRevert(Errors.InvalidFeeSplit.selector);
        new BeaconProxy(
            address(watermarkFeeManagerBeacon), abi.encodeCall(IMachinePeriphery.initialize, (abi.encode(initParams)))
        );

        initParams.initialMgmtFeeSplitBps = new uint256[](1);

        // Length mismatch between bps split and receivers
        vm.expectRevert(Errors.InvalidFeeSplit.selector);
        new BeaconProxy(
            address(watermarkFeeManagerBeacon), abi.encodeCall(IMachinePeriphery.initialize, (abi.encode(initParams)))
        );

        initParams.initialMgmtFeeReceivers = new address[](2);
        initParams.initialMgmtFeeReceivers[0] = address(0x123);
        initParams.initialMgmtFeeReceivers[1] = address(0x456);

        initParams.initialMgmtFeeSplitBps = new uint256[](2);
        initParams.initialMgmtFeeSplitBps[0] = 3_500;
        initParams.initialMgmtFeeSplitBps[1] = 6_000;

        // total bps smaller than 10_000
        vm.expectRevert(Errors.InvalidFeeSplit.selector);
        new BeaconProxy(
            address(watermarkFeeManagerBeacon), abi.encodeCall(IMachinePeriphery.initialize, (abi.encode(initParams)))
        );

        initParams.initialMgmtFeeSplitBps[1] = 7_000;

        // total bps greater than 10_000
        vm.expectRevert(Errors.InvalidFeeSplit.selector);
        new BeaconProxy(
            address(watermarkFeeManagerBeacon), abi.encodeCall(IMachinePeriphery.initialize, (abi.encode(initParams)))
        );
    }

    function test_RevertWhen_InvalidPerfFeeSplit() public {
        IWatermarkFeeManager.WatermarkFeeManagerInitParams memory initParams = _getWatermarkFeeManagerInitParams();

        initParams.initialPerfFeeReceivers = new address[](0);
        initParams.initialPerfFeeSplitBps = new uint256[](0);

        vm.startPrank(dao);

        // Empty fee split
        vm.expectRevert(Errors.InvalidFeeSplit.selector);
        new BeaconProxy(
            address(watermarkFeeManagerBeacon), abi.encodeCall(IMachinePeriphery.initialize, (abi.encode(initParams)))
        );

        initParams.initialPerfFeeSplitBps = new uint256[](1);

        // Length mismatch between bps split and receivers
        vm.expectRevert(Errors.InvalidFeeSplit.selector);
        new BeaconProxy(
            address(watermarkFeeManagerBeacon), abi.encodeCall(IMachinePeriphery.initialize, (abi.encode(initParams)))
        );

        initParams.initialPerfFeeReceivers = new address[](2);
        initParams.initialPerfFeeReceivers[0] = address(0x123);
        initParams.initialPerfFeeReceivers[1] = address(0x456);

        initParams.initialPerfFeeSplitBps = new uint256[](2);
        initParams.initialPerfFeeSplitBps[0] = 3_500;
        initParams.initialPerfFeeSplitBps[1] = 6_000;

        // total bps smaller than 10_000
        vm.expectRevert(Errors.InvalidFeeSplit.selector);
        new BeaconProxy(
            address(watermarkFeeManagerBeacon), abi.encodeCall(IMachinePeriphery.initialize, (abi.encode(initParams)))
        );

        initParams.initialPerfFeeSplitBps[1] = 7_000;

        // total bps greater than 10_000
        vm.expectRevert(Errors.InvalidFeeSplit.selector);
        new BeaconProxy(
            address(watermarkFeeManagerBeacon), abi.encodeCall(IMachinePeriphery.initialize, (abi.encode(initParams)))
        );
    }

    function _getWatermarkFeeManagerInitParams()
        internal
        view
        returns (IWatermarkFeeManager.WatermarkFeeManagerInitParams memory)
    {
        uint256[] memory dummyFeeSplitBps = new uint256[](1);
        dummyFeeSplitBps[0] = 10_000;
        address[] memory dummyFeeSplitReceivers = new address[](1);
        dummyFeeSplitReceivers[0] = dao;

        return IWatermarkFeeManager.WatermarkFeeManagerInitParams({
            initialMgmtFeeRatePerSecond: DEFAULT_WATERMARK_FEE_MANAGER_MGMT_FEE_RATE_PER_SECOND,
            initialSmFeeRatePerSecond: DEFAULT_WATERMARK_FEE_MANAGER_SM_FEE_RATE_PER_SECOND,
            initialPerfFeeRate: DEFAULT_WATERMARK_FEE_MANAGER_PERF_FEE_RATE,
            initialMgmtFeeSplitBps: dummyFeeSplitBps,
            initialMgmtFeeReceivers: dummyFeeSplitReceivers,
            initialPerfFeeSplitBps: dummyFeeSplitBps,
            initialPerfFeeReceivers: dummyFeeSplitReceivers
        });
    }
}
