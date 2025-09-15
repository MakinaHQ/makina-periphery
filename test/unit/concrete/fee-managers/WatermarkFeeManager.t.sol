// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {IAccessManaged} from "@openzeppelin/contracts/access/manager/IAccessManaged.sol";

import {Machine} from "@makina-core/machine/Machine.sol";

import {Errors} from "src/libraries/Errors.sol";
import {IWatermarkFeeManager} from "src/interfaces/IWatermarkFeeManager.sol";
import {IMachinePeriphery} from "src/interfaces/IMachinePeriphery.sol";
import {WatermarkFeeManager} from "src/fee-managers/WatermarkFeeManager.sol";

import {
    MachinePeriphery_Util_Concrete_Test,
    Getter_Setter_MachinePeriphery_Util_Concrete_Test
} from "../machine-periphery/MachinePeriphery.t.sol";
import {Unit_Concrete_Test} from "../UnitConcrete.t.sol";

abstract contract WatermarkFeeManager_Util_Concrete_Test is MachinePeriphery_Util_Concrete_Test {
    WatermarkFeeManager public watermarkFeeManager;

    address public FEE_RECEIVER;

    function setUp() public virtual override {
        Unit_Concrete_Test.setUp();

        FEE_RECEIVER = dao;

        uint256[] memory dummyFeeSplitBps = new uint256[](1);
        dummyFeeSplitBps[0] = 10_000;
        address[] memory dummyFeeSplitReceivers = new address[](1);
        dummyFeeSplitReceivers[0] = FEE_RECEIVER;

        vm.prank(dao);
        watermarkFeeManager = WatermarkFeeManager(
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

        machinePeriphery = IMachinePeriphery(address(watermarkFeeManager));

        (Machine machine,) =
            _deployMachine(address(accountingToken), address(0), address(0), address(watermarkFeeManager));
        _machineAddr = address(machine);
    }
}

contract Getters_Setters_AsyncRedeemer_Util_Concrete_Test is
    Getter_Setter_MachinePeriphery_Util_Concrete_Test,
    WatermarkFeeManager_Util_Concrete_Test
{
    function setUp()
        public
        virtual
        override(WatermarkFeeManager_Util_Concrete_Test, MachinePeriphery_Util_Concrete_Test)
    {
        WatermarkFeeManager_Util_Concrete_Test.setUp();
    }

    modifier withMachine(address _machine) {
        vm.prank(dao);
        hubPeripheryFactory.setMachine(address(watermarkFeeManager), _machine);

        _;
    }

    function test_Getters() public view {
        assertEq(watermarkFeeManager.mgmtFeeRatePerSecond(), DEFAULT_WATERMARK_FEE_MANAGER_MGMT_FEE_RATE_PER_SECOND);
        assertEq(watermarkFeeManager.smFeeRatePerSecond(), DEFAULT_WATERMARK_FEE_MANAGER_SM_FEE_RATE_PER_SECOND);
        assertEq(watermarkFeeManager.perfFeeRate(), DEFAULT_WATERMARK_FEE_MANAGER_PERF_FEE_RATE);

        assertEq(watermarkFeeManager.mgmtFeeSplitBps().length, 1);
        assertEq(watermarkFeeManager.mgmtFeeSplitBps()[0], 10_000);
        assertEq(watermarkFeeManager.mgmtFeeReceivers().length, 1);
        assertEq(watermarkFeeManager.mgmtFeeReceivers()[0], FEE_RECEIVER);

        assertEq(watermarkFeeManager.perfFeeSplitBps().length, 1);
        assertEq(watermarkFeeManager.perfFeeSplitBps()[0], 10_000);
        assertEq(watermarkFeeManager.perfFeeReceivers().length, 1);
        assertEq(watermarkFeeManager.perfFeeReceivers()[0], FEE_RECEIVER);

        assertEq(watermarkFeeManager.sharePriceWatermark(), 0);
    }

    function test_authority_RevertWhen_MachineNotSet() public {
        vm.expectRevert(Errors.MachineNotSet.selector);
        watermarkFeeManager.authority();
    }

    function test_authority() public withMachine(_machineAddr) {
        assertEq(watermarkFeeManager.authority(), address(accessManager));
    }

    function test_SetMgmtFeeRate_RevertWhen_CallerWithoutRole() public withMachine(_machineAddr) {
        vm.expectRevert(abi.encodeWithSelector(IAccessManaged.AccessManagedUnauthorized.selector, address(this)));
        watermarkFeeManager.setMgmtFeeRatePerSecond(0);
    }

    function test_SetMgmtFeeRate_RevertWhen_MaxFeeRateValueExceeded() public withMachine(_machineAddr) {
        vm.expectRevert(Errors.MaxFeeRateValueExceeded.selector);
        vm.prank(dao);
        watermarkFeeManager.setMgmtFeeRatePerSecond(1e18 + 1);
    }

    function test_SetMgmtFeeRatePerSecond() public withMachine(_machineAddr) {
        uint256 newMgmtFeeRate = 1e18;
        vm.expectEmit(true, true, false, false, address(watermarkFeeManager));
        emit IWatermarkFeeManager.MgmtFeeRatePerSecondChanged(
            DEFAULT_WATERMARK_FEE_MANAGER_MGMT_FEE_RATE_PER_SECOND, newMgmtFeeRate
        );
        vm.prank(dao);
        watermarkFeeManager.setMgmtFeeRatePerSecond(newMgmtFeeRate);
        assertEq(watermarkFeeManager.mgmtFeeRatePerSecond(), newMgmtFeeRate);
    }

    function test_SetSmFeeRate_RevertWhen_CallerWithoutRole() public withMachine(_machineAddr) {
        vm.expectRevert(abi.encodeWithSelector(IAccessManaged.AccessManagedUnauthorized.selector, address(this)));
        watermarkFeeManager.setSmFeeRatePerSecond(0);
    }

    function test_SetSmFeeRate_RevertWhen_MaxFeeRateValueExceeded() public withMachine(_machineAddr) {
        vm.expectRevert(Errors.MaxFeeRateValueExceeded.selector);
        vm.prank(dao);
        watermarkFeeManager.setSmFeeRatePerSecond(1e18 + 1);
    }

    function test_SetSmFeeRatePerSecond() public withMachine(_machineAddr) {
        uint256 newSmFeeRate = 1e18;
        vm.expectEmit(true, true, false, false, address(watermarkFeeManager));
        emit IWatermarkFeeManager.SmFeeRatePerSecondChanged(
            DEFAULT_WATERMARK_FEE_MANAGER_SM_FEE_RATE_PER_SECOND, newSmFeeRate
        );
        vm.prank(dao);
        watermarkFeeManager.setSmFeeRatePerSecond(newSmFeeRate);
        assertEq(watermarkFeeManager.smFeeRatePerSecond(), newSmFeeRate);
    }

    function test_SetPerfFeeRate_RevertWhen_CallerWithoutRole() public withMachine(_machineAddr) {
        vm.expectRevert(abi.encodeWithSelector(IAccessManaged.AccessManagedUnauthorized.selector, address(this)));
        watermarkFeeManager.setPerfFeeRate(0);
    }

    function test_SetPerfFeeRate_RevertWhen_MaxFeeRateValueExceeded() public withMachine(_machineAddr) {
        vm.expectRevert(Errors.MaxFeeRateValueExceeded.selector);
        vm.prank(dao);
        watermarkFeeManager.setPerfFeeRate(1e18 + 1);
    }

    function test_SetPerfFeeRate() public withMachine(_machineAddr) {
        uint256 newPerfFeeRate = 1e18;
        vm.expectEmit(true, true, false, false, address(watermarkFeeManager));
        emit IWatermarkFeeManager.PerfFeeRateChanged(DEFAULT_WATERMARK_FEE_MANAGER_PERF_FEE_RATE, newPerfFeeRate);
        vm.prank(dao);
        watermarkFeeManager.setPerfFeeRate(newPerfFeeRate);
        assertEq(watermarkFeeManager.perfFeeRate(), newPerfFeeRate);
    }

    function test_SetMgmtFeeSplit_RevertWhen_CallerWithoutRole() public withMachine(_machineAddr) {
        address[] memory newMgmtFeeReceivers = new address[](0);
        uint256[] memory newMgmtFeeSplitBps = new uint256[](0);

        vm.expectRevert(abi.encodeWithSelector(IAccessManaged.AccessManagedUnauthorized.selector, address(this)));
        watermarkFeeManager.setMgmtFeeSplit(newMgmtFeeReceivers, newMgmtFeeSplitBps);
    }

    function test_SetMgmtFeeSplit_RevertWhen_InvalidFeeSplit() public withMachine(_machineAddr) {
        address[] memory newMgmtFeeReceivers = new address[](0);
        uint256[] memory newMgmtFeeSplitBps = new uint256[](0);

        vm.startPrank(dao);

        // Empty fee split
        vm.expectRevert(Errors.InvalidFeeSplit.selector);
        watermarkFeeManager.setMgmtFeeSplit(newMgmtFeeReceivers, newMgmtFeeSplitBps);

        newMgmtFeeSplitBps = new uint256[](1);

        // Length mismatch between bps split and receivers
        vm.expectRevert(Errors.InvalidFeeSplit.selector);
        watermarkFeeManager.setMgmtFeeSplit(newMgmtFeeReceivers, newMgmtFeeSplitBps);

        newMgmtFeeReceivers = new address[](2);
        newMgmtFeeReceivers[0] = address(0x123);
        newMgmtFeeReceivers[1] = address(0x456);

        newMgmtFeeSplitBps = new uint256[](2);
        newMgmtFeeSplitBps[0] = 3_500;
        newMgmtFeeSplitBps[1] = 6_000;

        // total bps smaller than 10_000
        vm.expectRevert(Errors.InvalidFeeSplit.selector);
        watermarkFeeManager.setMgmtFeeSplit(newMgmtFeeReceivers, newMgmtFeeSplitBps);

        newMgmtFeeSplitBps[1] = 7_000;

        // total bps greater than 10_000
        vm.expectRevert(Errors.InvalidFeeSplit.selector);
        watermarkFeeManager.setMgmtFeeSplit(newMgmtFeeReceivers, newMgmtFeeSplitBps);
    }

    function test_SetMgmtFeeSplit() public withMachine(_machineAddr) {
        address[] memory newMgmtFeeReceivers = new address[](2);
        newMgmtFeeReceivers[0] = address(0x123);
        newMgmtFeeReceivers[1] = address(0x456);
        uint256[] memory newMgmtFeeSplitBps = new uint256[](2);
        newMgmtFeeSplitBps[0] = 3_500;
        newMgmtFeeSplitBps[1] = 6_500;

        vm.expectEmit(true, true, false, false, address(watermarkFeeManager));
        emit IWatermarkFeeManager.MgmtFeeSplitChanged();
        vm.prank(dao);
        watermarkFeeManager.setMgmtFeeSplit(newMgmtFeeReceivers, newMgmtFeeSplitBps);

        assertEq(watermarkFeeManager.mgmtFeeReceivers().length, 2);
        assertEq(watermarkFeeManager.mgmtFeeReceivers()[0], address(0x123));
        assertEq(watermarkFeeManager.mgmtFeeReceivers()[1], address(0x456));
        assertEq(watermarkFeeManager.mgmtFeeSplitBps().length, 2);
        assertEq(watermarkFeeManager.mgmtFeeSplitBps()[0], 3_500);
        assertEq(watermarkFeeManager.mgmtFeeSplitBps()[1], 6_500);
    }

    function test_SetPerfFeeSplit_RevertWhen_CallerWithoutRole() public withMachine(_machineAddr) {
        address[] memory newPerfFeeReceivers = new address[](0);
        uint256[] memory newPerfFeeSplitBps = new uint256[](0);

        vm.expectRevert(abi.encodeWithSelector(IAccessManaged.AccessManagedUnauthorized.selector, address(this)));
        watermarkFeeManager.setPerfFeeSplit(newPerfFeeReceivers, newPerfFeeSplitBps);
    }

    function test_SetPerfFeeSplit_RevertWhen_InvalidFeeSplit() public withMachine(_machineAddr) {
        address[] memory newPerfFeeReceivers = new address[](0);
        uint256[] memory newPerfFeeSplitBps = new uint256[](0);

        vm.startPrank(dao);

        // Empty fee split
        vm.expectRevert(Errors.InvalidFeeSplit.selector);
        watermarkFeeManager.setPerfFeeSplit(newPerfFeeReceivers, newPerfFeeSplitBps);

        newPerfFeeSplitBps = new uint256[](1);

        // Length mismatch between bps split and receivers
        vm.expectRevert(Errors.InvalidFeeSplit.selector);
        watermarkFeeManager.setPerfFeeSplit(newPerfFeeReceivers, newPerfFeeSplitBps);

        newPerfFeeReceivers = new address[](2);
        newPerfFeeReceivers[0] = address(0x123);
        newPerfFeeReceivers[1] = address(0x456);

        newPerfFeeSplitBps = new uint256[](2);
        newPerfFeeSplitBps[0] = 3_500;
        newPerfFeeSplitBps[1] = 6_000;

        // total bps smaller than 10_000
        vm.expectRevert(Errors.InvalidFeeSplit.selector);
        watermarkFeeManager.setPerfFeeSplit(newPerfFeeReceivers, newPerfFeeSplitBps);

        newPerfFeeSplitBps[1] = 7_000;

        // total bps greater than 10_000
        vm.expectRevert(Errors.InvalidFeeSplit.selector);
        watermarkFeeManager.setPerfFeeSplit(newPerfFeeReceivers, newPerfFeeSplitBps);
    }

    function test_SetPerfFeeSplit() public withMachine(_machineAddr) {
        address[] memory newPerfFeeReceivers = new address[](2);
        newPerfFeeReceivers[0] = address(0x123);
        newPerfFeeReceivers[1] = address(0x456);
        uint256[] memory newPerfFeeSplitBps = new uint256[](2);
        newPerfFeeSplitBps[0] = 3_500;
        newPerfFeeSplitBps[1] = 6_500;

        vm.expectEmit(true, true, false, false, address(watermarkFeeManager));
        emit IWatermarkFeeManager.PerfFeeSplitChanged();
        vm.prank(dao);
        watermarkFeeManager.setPerfFeeSplit(newPerfFeeReceivers, newPerfFeeSplitBps);

        assertEq(watermarkFeeManager.perfFeeReceivers().length, 2);
        assertEq(watermarkFeeManager.perfFeeReceivers()[0], address(0x123));
        assertEq(watermarkFeeManager.perfFeeReceivers()[1], address(0x456));
        assertEq(watermarkFeeManager.perfFeeSplitBps().length, 2);
        assertEq(watermarkFeeManager.perfFeeSplitBps()[0], 3_500);
        assertEq(watermarkFeeManager.perfFeeSplitBps()[1], 6_500);
    }
}
