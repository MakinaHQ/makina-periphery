// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {BooleanHelper} from "src/weiroll-helpers/BooleanHelper.sol";

import {Unit_Concrete_Test} from "../../UnitConcrete.t.sol";

contract BooleanHelper_Unit_Concrete_Test is Unit_Concrete_Test {
    BooleanHelper public booleanHelper;

    function setUp() public virtual override {
        Unit_Concrete_Test.setUp();

        booleanHelper = new BooleanHelper();
    }

    function test_Not() public view {
        assertEq(booleanHelper.not(true), false);
        assertEq(booleanHelper.not(false), true);
    }

    function test_And() public view {
        assertEq(booleanHelper.and(true, true), true);
        assertEq(booleanHelper.and(true, false), false);
        assertEq(booleanHelper.and(false, true), false);
        assertEq(booleanHelper.and(false, false), false);
    }

    function test_Or() public view {
        assertEq(booleanHelper.or(true, true), true);
        assertEq(booleanHelper.or(true, false), true);
        assertEq(booleanHelper.or(false, true), true);
        assertEq(booleanHelper.or(false, false), false);
    }

    function test_RevertIfTrue() public {
        booleanHelper.revertIfTrue(false);

        vm.expectRevert(BooleanHelper.ConditionIsTrue.selector);
        booleanHelper.revertIfTrue(true);
    }

    function test_RevertIfFalse() public {
        booleanHelper.revertIfFalse(true);

        vm.expectRevert(BooleanHelper.ConditionIsFalse.selector);
        booleanHelper.revertIfFalse(false);
    }
}
