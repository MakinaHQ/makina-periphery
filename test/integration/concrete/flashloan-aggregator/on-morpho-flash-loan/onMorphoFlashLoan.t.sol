// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {ICaliber} from "@makina-core/interfaces/ICaliber.sol";

import {IFlashloanAggregator} from "src/interfaces/IFlashloanAggregator.sol";
import {FlashloanAggregator} from "src/flashloans/FlashloanAggregator.sol";

import {FlashloanAggregator_Integration_Concrete_Test} from "../FlashloanAggregator.t.sol";

contract OnMorphoFlashLoan_Integration_Concrete_Test is FlashloanAggregator_Integration_Concrete_Test {
    function test_RevertWhen_InvalidUserDataHash() public {
        vm.expectRevert(IFlashloanAggregator.InvalidUserDataHash.selector);
        flashloanAggregator.onMorphoFlashLoan(0, "");
    }

    function test_RevertWhen_NotMorpho() public {
        flashloanAggregator = new FlashloanAggregator(
            address(hubCoreFactory), address(0), address(0), address(this), address(0), address(0), address(0)
        );

        ICaliber.Instruction memory instruction;

        IFlashloanAggregator.FlashloanRequest memory request = IFlashloanAggregator.FlashloanRequest({
            provider: IFlashloanAggregator.FlashloanProvider.MORPHO,
            instruction: instruction,
            token: address(0),
            amount: 0
        });

        vm.expectRevert(IFlashloanAggregator.NotMorpho.selector);
        vm.prank(address(caliberAddr));
        flashloanAggregator.requestFlashloan(request);
    }

    /// @dev Mocks the flashLoan function of the Morpho contract and simulates faulty behavior.
    function flashLoan(address, uint256 assets, bytes calldata data) external {
        vm.prank(address(0));
        flashloanAggregator.onMorphoFlashLoan(assets, data);
    }
}
