// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";

import {ICaliber} from "@makina-core/interfaces/ICaliber.sol";

import {IFlashloanAggregator} from "src/interfaces/IFlashloanAggregator.sol";
import {FlashloanAggregator} from "src/flashloans/FlashloanAggregator.sol";

import {FlashloanAggregator_Integration_Concrete_Test} from "../FlashloanAggregator.t.sol";

contract BalancerV3FlashloanCallback_Integration_Concrete_Test is FlashloanAggregator_Integration_Concrete_Test {
    function test_RevertWhen_InvalidUserDataHash() public {
        ICaliber.Instruction memory instruction;

        vm.expectRevert(IFlashloanAggregator.InvalidUserDataHash.selector);
        flashloanAggregator.balancerV3FlashloanCallback(address(0), instruction, address(0), 0);
    }

    function test_RevertWhen_NotBalancerV3Pool() public {
        flashloanAggregator = new FlashloanAggregator(
            address(hubCoreFactory), address(0), address(this), address(0), address(0), address(0), address(0)
        );

        ICaliber.Instruction memory instruction;

        IFlashloanAggregator.FlashloanRequest memory request = IFlashloanAggregator.FlashloanRequest({
            provider: IFlashloanAggregator.FlashloanProvider.BALANCER_V3,
            instruction: instruction,
            token: address(0),
            amount: 10e18
        });

        vm.expectRevert(IFlashloanAggregator.NotBalancerV3Pool.selector);
        vm.prank(address(caliberAddr));
        flashloanAggregator.requestFlashloan(request);
    }

    /// @dev Mocks the unlock function of the Balancer V3 vault and simulates faulty behavior.
    function unlock(bytes calldata data) external returns (bytes memory) {
        vm.prank(address(0));
        Address.functionCall(address(flashloanAggregator), data);
        return "";
    }
}
