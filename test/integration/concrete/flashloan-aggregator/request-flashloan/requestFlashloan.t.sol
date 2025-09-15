// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {StdStorage, stdStorage} from "forge-std/StdStorage.sol";

import {ICaliber} from "@makina-core/interfaces/ICaliber.sol";

import {IFlashloanAggregator} from "src/interfaces/IFlashloanAggregator.sol";
import {FlashloanAggregator} from "src/flashloans/FlashloanAggregator.sol";

import {FlashloanAggregator_Integration_Concrete_Test} from "../FlashloanAggregator.t.sol";

contract RequestFlashloan_Integration_Concrete_Test is FlashloanAggregator_Integration_Concrete_Test {
    using stdStorage for StdStorage;

    function setUp() public override {
        FlashloanAggregator_Integration_Concrete_Test.setUp();

        flashloanAggregator = new FlashloanAggregator(
            address(hubCoreFactory), address(0), address(0), address(0), address(0), address(0), address(0)
        );
    }

    function test_RevertWhen_CallerNotCaliber() public {
        IFlashloanAggregator.FlashloanRequest memory request;

        vm.expectRevert(IFlashloanAggregator.NotCaliber.selector);
        flashloanAggregator.requestFlashloan(request);
    }

    function test_RevertWhen_AaveV3PoolNotSet() public {
        ICaliber.Instruction memory instruction;

        IFlashloanAggregator.FlashloanRequest memory request = IFlashloanAggregator.FlashloanRequest({
            provider: IFlashloanAggregator.FlashloanProvider.AAVE_V3,
            instruction: instruction,
            token: address(0),
            amount: 0
        });

        vm.expectRevert(IFlashloanAggregator.AaveV3PoolNotSet.selector);
        vm.prank(caliberAddr);
        flashloanAggregator.requestFlashloan(request);
    }

    function test_RevertWhen_BalancerV2PoolNotSet() public {
        ICaliber.Instruction memory instruction;

        IFlashloanAggregator.FlashloanRequest memory request = IFlashloanAggregator.FlashloanRequest({
            provider: IFlashloanAggregator.FlashloanProvider.BALANCER_V2,
            instruction: instruction,
            token: address(0),
            amount: 0
        });

        vm.expectRevert(IFlashloanAggregator.BalancerV2PoolNotSet.selector);
        vm.prank(caliberAddr);
        flashloanAggregator.requestFlashloan(request);
    }

    function test_RevertWhen_BalancerV3PoolNotSet() public {
        ICaliber.Instruction memory instruction;

        IFlashloanAggregator.FlashloanRequest memory request = IFlashloanAggregator.FlashloanRequest({
            provider: IFlashloanAggregator.FlashloanProvider.BALANCER_V3,
            instruction: instruction,
            token: address(0),
            amount: 0
        });

        vm.expectRevert(IFlashloanAggregator.BalancerV3PoolNotSet.selector);
        vm.prank(caliberAddr);
        flashloanAggregator.requestFlashloan(request);
    }

    function test_RevertWhen_MorphoPoolNotSet() public {
        ICaliber.Instruction memory instruction;

        IFlashloanAggregator.FlashloanRequest memory request = IFlashloanAggregator.FlashloanRequest({
            provider: IFlashloanAggregator.FlashloanProvider.MORPHO,
            instruction: instruction,
            token: address(0),
            amount: 0
        });

        vm.expectRevert(IFlashloanAggregator.MorphoPoolNotSet.selector);
        vm.prank(caliberAddr);
        flashloanAggregator.requestFlashloan(request);
    }

    function test_RevertWhen_DssFlashNotSet() public {
        ICaliber.Instruction memory instruction;

        IFlashloanAggregator.FlashloanRequest memory request = IFlashloanAggregator.FlashloanRequest({
            provider: IFlashloanAggregator.FlashloanProvider.DSS_FLASH,
            instruction: instruction,
            token: address(0),
            amount: 0
        });

        vm.expectRevert(IFlashloanAggregator.DssFlashNotSet.selector);
        vm.prank(caliberAddr);
        flashloanAggregator.requestFlashloan(request);
    }

    function test_RevertWhen_InvalidToken() public {
        flashloanAggregator = new FlashloanAggregator(
            address(hubCoreFactory), address(0), address(0), address(0), dssFlash, address(0), dai
        );

        ICaliber.Instruction memory instruction;

        IFlashloanAggregator.FlashloanRequest memory request = IFlashloanAggregator.FlashloanRequest({
            provider: IFlashloanAggregator.FlashloanProvider.DSS_FLASH,
            instruction: instruction,
            token: address(0),
            amount: 0
        });

        vm.expectRevert(IFlashloanAggregator.InvalidToken.selector);
        vm.prank(caliberAddr);
        flashloanAggregator.requestFlashloan(request);
    }
}
