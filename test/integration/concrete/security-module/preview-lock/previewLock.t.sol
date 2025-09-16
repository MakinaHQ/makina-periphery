// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {Errors} from "src/libraries/Errors.sol";

import {SecurityModule_Integration_Concrete_Test} from "../SecurityModule.t.sol";

contract PreviewLock_Integration_Concrete_Test is SecurityModule_Integration_Concrete_Test {
    function test_RevertGiven_SlashingSettlementOngoing() public {
        vm.prank(securityCouncil);
        securityModule.slash(0);

        vm.expectRevert(Errors.SlashingSettlementOngoing.selector);
        securityModule.previewLock(0);
    }

    function test_PreviewLock() public view {
        uint256 inputAmount = 3e18;
        uint256 expectedShares = securityModule.previewLock(inputAmount);
        assertEq(expectedShares, inputAmount);
    }
}
