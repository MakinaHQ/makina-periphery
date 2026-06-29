// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {CoreErrors} from "src/libraries/Errors.sol";
import {ISanctionsList} from "src/interfaces/ISanctionsList.sol";

import {Unit_Concrete_Test} from "../UnitConcrete.t.sol";

abstract contract SanctionsList_Unit_Concrete_Test is Unit_Concrete_Test {
    ISanctionsList internal sanctionsList;

    // solhint-disable-next-line no-empty-blocks
    function setUp() public virtual override {}

    function test_Getters() public view {
        assertEq(sanctionsList.sanctionsOracle(), address(sanctionsOracle));
        assertFalse(sanctionsList.isSanctionsCheckEnabled());
    }

    function test_SetSanctionsCheckStatus_RevertGiven_CallerNotRM() public {
        vm.expectRevert(CoreErrors.UnauthorizedCaller.selector);
        sanctionsList.setSanctionsCheckStatus(true);
    }

    function test_SetSanctionsCheckStatus() public {
        assertFalse(sanctionsList.isSanctionsCheckEnabled());

        vm.expectEmit(true, false, false, false, address(sanctionsList));
        emit ISanctionsList.SanctionsCheckStatusChanged(true);
        vm.prank(riskManager);
        sanctionsList.setSanctionsCheckStatus(true);

        assertTrue(sanctionsList.isSanctionsCheckEnabled());

        vm.expectEmit(true, false, false, false, address(sanctionsList));
        emit ISanctionsList.SanctionsCheckStatusChanged(false);
        vm.prank(riskManager);
        sanctionsList.setSanctionsCheckStatus(false);

        assertFalse(sanctionsList.isSanctionsCheckEnabled());
    }
}
