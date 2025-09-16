// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {IPoolAddressesProvider} from "@aave/interfaces/IPoolAddressesProvider.sol";

import {ICaliber} from "@makina-core/interfaces/ICaliber.sol";

import {IFlashloanAggregator} from "src/interfaces/IFlashloanAggregator.sol";

import {FlashLoanHelpers} from "../../../utils/FlashLoanHelpers.sol";
import {MockCaliber} from "../../../mocks/MockCaliber.sol";

import {FlashloanAggregator_Fork_Test} from "../FlashloanAggregator.t.sol";

contract RequestFlashloan_Fork_Test is FlashloanAggregator_Fork_Test {
    function test_AaveV3_RevertWhen_PremiumTooLow() public {
        ICaliber.Instruction memory instruction;
        address token = weth;
        uint256 amount = 10e18;

        uint256 premium = FlashLoanHelpers.getAaveV3FlashloanPremium(
            IPoolAddressesProvider(flashloanAggregator.aaveV3AddressProvider()).getPool(), amount
        ) - 1;
        deal(token, address(mockCaliber), premium);
        mockCaliber.setFlashloanPremium(premium);

        IFlashloanAggregator.FlashloanRequest memory request = IFlashloanAggregator.FlashloanRequest({
            provider: IFlashloanAggregator.FlashloanProvider.AAVE_V3,
            instruction: instruction,
            token: token,
            amount: amount
        });

        vm.expectRevert();
        vm.prank(address(mockCaliber));
        flashloanAggregator.requestFlashloan(request);
    }

    function test_AaveV3() public {
        ICaliber.Instruction memory instruction;
        address token = weth;
        uint256 amount = 10e18;

        uint256 premium = FlashLoanHelpers.getAaveV3FlashloanPremium(
            IPoolAddressesProvider(flashloanAggregator.aaveV3AddressProvider()).getPool(), amount
        );
        deal(token, address(mockCaliber), premium);
        mockCaliber.setFlashloanPremium(premium);

        IFlashloanAggregator.FlashloanRequest memory request = IFlashloanAggregator.FlashloanRequest({
            provider: IFlashloanAggregator.FlashloanProvider.AAVE_V3,
            instruction: instruction,
            token: token,
            amount: amount
        });

        vm.expectEmit(false, false, false, true, address(mockCaliber));
        emit MockCaliber.ParamsHash(keccak256(abi.encode(instruction, token, amount)));

        vm.prank(address(mockCaliber));
        flashloanAggregator.requestFlashloan(request);
    }

    function test_BalancerV2() public {
        ICaliber.Instruction memory instruction;
        address token = weth;
        uint256 amount = 10e18;

        IFlashloanAggregator.FlashloanRequest memory request = IFlashloanAggregator.FlashloanRequest({
            provider: IFlashloanAggregator.FlashloanProvider.BALANCER_V2,
            instruction: instruction,
            token: token,
            amount: amount
        });

        vm.expectEmit(false, false, false, true, address(mockCaliber));
        emit MockCaliber.ParamsHash(keccak256(abi.encode(instruction, token, amount)));

        vm.prank(address(mockCaliber));
        flashloanAggregator.requestFlashloan(request);
    }

    function test_BalancerV3() public {
        ICaliber.Instruction memory instruction;
        address token = weth;
        uint256 amount = 10e18;

        IFlashloanAggregator.FlashloanRequest memory request = IFlashloanAggregator.FlashloanRequest({
            provider: IFlashloanAggregator.FlashloanProvider.BALANCER_V3,
            instruction: instruction,
            token: token,
            amount: amount
        });

        vm.expectEmit(false, false, false, true, address(mockCaliber));
        emit MockCaliber.ParamsHash(keccak256(abi.encode(instruction, token, amount)));

        vm.prank(address(mockCaliber));
        flashloanAggregator.requestFlashloan(request);
    }

    function test_Morpho() public {
        ICaliber.Instruction memory instruction;
        address token = weth;
        uint256 amount = 10e18;

        IFlashloanAggregator.FlashloanRequest memory request = IFlashloanAggregator.FlashloanRequest({
            provider: IFlashloanAggregator.FlashloanProvider.MORPHO,
            instruction: instruction,
            token: token,
            amount: amount
        });

        vm.expectEmit(false, false, false, true, address(mockCaliber));
        emit MockCaliber.ParamsHash(keccak256(abi.encode(instruction, token, amount)));

        vm.prank(address(mockCaliber));
        flashloanAggregator.requestFlashloan(request);
    }

    function test_dssFlash() public {
        ICaliber.Instruction memory instruction;
        address token = flashloanAggregator.dai();
        uint256 amount = 10e18;

        IFlashloanAggregator.FlashloanRequest memory request = IFlashloanAggregator.FlashloanRequest({
            provider: IFlashloanAggregator.FlashloanProvider.DSS_FLASH,
            instruction: instruction,
            token: token,
            amount: amount
        });

        vm.expectEmit(false, false, false, true, address(mockCaliber));
        emit MockCaliber.ParamsHash(keccak256(abi.encode(instruction, token, amount)));

        vm.prank(address(mockCaliber));
        flashloanAggregator.requestFlashloan(request);
    }
}
