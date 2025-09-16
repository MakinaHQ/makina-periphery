// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {IERC20 as BalancerIERC20} from "@balancer-v2-interfaces/solidity-utils/openzeppelin/IERC20.sol";
import {IFlashLoanRecipient as BalancerV2FlashloanRecipient} from
    "@balancer-v2-interfaces/vault/IFlashLoanRecipient.sol";

import {ICaliber} from "@makina-core/interfaces/ICaliber.sol";

import {IFlashloanAggregator} from "src/interfaces/IFlashloanAggregator.sol";
import {FlashloanAggregator} from "src/flashloans/FlashloanAggregator.sol";

import {FlashloanAggregator_Integration_Concrete_Test} from "../FlashloanAggregator.t.sol";

contract ReceiveFlashloan_Integration_Concrete_Test is FlashloanAggregator_Integration_Concrete_Test {
    uint8 private constant FAULTY_MODE_NOT_BALANCER_V2_POOL = 1;
    uint8 private constant FAULTY_MODE_INVALID_TOKENS_LENGTH = 2;
    uint8 private constant FAULTY_MODE_INVALID_AMOUNTS_LENGTH = 3;
    uint8 private constant FAULTY_MODE_INVALID_FEEAMOUNTS_LENGTH = 4;

    uint8 private faultyMode;

    function test_RevertWhen_InvalidUserDataHash() public {
        vm.expectRevert(IFlashloanAggregator.InvalidUserDataHash.selector);
        flashloanAggregator.receiveFlashLoan(new BalancerIERC20[](0), new uint256[](0), new uint256[](0), "");
    }

    function test_RevertWhen_NotBalancerV2Pool() public {
        flashloanAggregator = new FlashloanAggregator(
            address(hubCoreFactory), address(this), address(0), address(0), address(0), address(0), address(0)
        );

        ICaliber.Instruction memory instruction;
        BalancerIERC20[] memory tokens = new BalancerIERC20[](1);
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 10e18;
        uint256[] memory premiums = new uint256[](1);
        premiums[0] = 0;

        IFlashloanAggregator.FlashloanRequest memory request = IFlashloanAggregator.FlashloanRequest({
            provider: IFlashloanAggregator.FlashloanProvider.BALANCER_V2,
            instruction: instruction,
            token: address(tokens[0]),
            amount: amounts[0]
        });

        faultyMode = FAULTY_MODE_NOT_BALANCER_V2_POOL;

        vm.expectRevert(IFlashloanAggregator.NotBalancerV2Pool.selector);
        vm.prank(address(caliberAddr));
        flashloanAggregator.requestFlashloan(request);
    }

    function test_RevertWhen_InvalidParamsLength() public {
        flashloanAggregator = new FlashloanAggregator(
            address(hubCoreFactory), address(this), address(0), address(0), address(0), address(0), address(0)
        );

        ICaliber.Instruction memory instruction;

        IFlashloanAggregator.FlashloanRequest memory request = IFlashloanAggregator.FlashloanRequest({
            provider: IFlashloanAggregator.FlashloanProvider.BALANCER_V2,
            instruction: instruction,
            token: address(0),
            amount: 10e18
        });

        faultyMode = FAULTY_MODE_INVALID_TOKENS_LENGTH;

        vm.expectRevert(IFlashloanAggregator.InvalidParamsLength.selector);
        vm.prank(caliberAddr);
        flashloanAggregator.requestFlashloan(request);

        faultyMode = FAULTY_MODE_INVALID_AMOUNTS_LENGTH;

        vm.expectRevert(IFlashloanAggregator.InvalidParamsLength.selector);
        vm.prank(caliberAddr);
        flashloanAggregator.requestFlashloan(request);

        faultyMode = FAULTY_MODE_INVALID_FEEAMOUNTS_LENGTH;

        vm.expectRevert(IFlashloanAggregator.InvalidParamsLength.selector);
        vm.prank(caliberAddr);
        flashloanAggregator.requestFlashloan(request);
    }

    /// @dev Mocks the flashLoan function of the Balancer V2 vault and simulates faulty behavior.
    function flashLoan(
        BalancerV2FlashloanRecipient recipient,
        BalancerIERC20[] memory tokens,
        uint256[] memory amounts,
        bytes memory userData
    ) external {
        uint256 len = tokens.length;

        uint256[] memory fees = new uint256[](len);

        if (faultyMode == FAULTY_MODE_NOT_BALANCER_V2_POOL) {
            vm.prank(address(0));
        } else if (faultyMode == FAULTY_MODE_INVALID_TOKENS_LENGTH) {
            tokens = new BalancerIERC20[](len + 1);
        } else if (faultyMode == FAULTY_MODE_INVALID_AMOUNTS_LENGTH) {
            amounts = new uint256[](len + 1);
        } else if (faultyMode == FAULTY_MODE_INVALID_FEEAMOUNTS_LENGTH) {
            fees = new uint256[](len + 1);
        }

        recipient.receiveFlashLoan(tokens, amounts, fees, userData);
    }
}
