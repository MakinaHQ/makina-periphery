// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {SignedMathHelper} from "src/weiroll-helpers/SignedMathHelper.sol";

import {Unit_Concrete_Test} from "../../UnitConcrete.t.sol";

contract SignedMathHelper_Unit_concrete_Test is Unit_Concrete_Test {
    SignedMathHelper public signedMathHelper;

    function setUp() public virtual override {
        Unit_Concrete_Test.setUp();

        signedMathHelper = new SignedMathHelper();
    }

    function test_Add() public view {
        int256 a = 42;
        int256 b = 58;
        int256 expected = 100;

        assertEq(signedMathHelper.add(a, b), expected);

        a = -42;
        expected = 16;

        assertEq(signedMathHelper.add(a, b), expected);

        b = -58;
        expected = -100;

        assertEq(signedMathHelper.add(a, b), expected);
    }

    function test_Sub() public view {
        int256 a = 100;
        int256 b = 58;
        int256 expected = 42;

        assertEq(signedMathHelper.sub(a, b), expected);

        a = -100;
        expected = -158;

        assertEq(signedMathHelper.sub(a, b), expected);

        b = -58;
        expected = -42;

        assertEq(signedMathHelper.sub(a, b), expected);
    }

    function test_Mul() public view {
        int256 a = 6;
        int256 b = 7;
        int256 expected = 42;

        assertEq(signedMathHelper.mul(a, b), expected);

        a = -6;
        expected = -42;

        assertEq(signedMathHelper.mul(a, b), expected);

        b = -7;
        expected = 42;

        assertEq(signedMathHelper.mul(a, b), expected);
    }

    function test_Div() public {
        int256 a = 85;
        int256 b = 2;
        int256 expected = 42;

        assertEq(signedMathHelper.div(a, b), expected);

        a = -85;
        expected = -42;

        assertEq(signedMathHelper.div(a, b), expected);

        b = -2;
        expected = 42;

        assertEq(signedMathHelper.div(a, b), expected);

        vm.expectRevert();
        signedMathHelper.div(a, 0);
    }

    function test_Max() public view {
        int256 a = 42;
        int256 b = 84;

        assertEq(signedMathHelper.max(a, b), b);

        a = -42;

        assertEq(signedMathHelper.max(a, b), b);

        b = -84;
        assertEq(signedMathHelper.max(a, b), a);
    }

    function test_Min() public view {
        int256 a = 42;
        int256 b = 84;

        assertEq(signedMathHelper.min(a, b), a);

        a = -42;
        assertEq(signedMathHelper.min(a, b), a);

        b = -84;
        assertEq(signedMathHelper.min(a, b), b);
    }

    function test_Average() public view {
        int256 a = 40;
        int256 b = 44;
        int256 expected = 42;

        assertEq(signedMathHelper.average(a, b), expected);

        a = -40;
        expected = 2;
        assertEq(signedMathHelper.average(a, b), expected);

        b = -44;
        expected = -42;

        assertEq(signedMathHelper.average(a, b), expected);
    }

    function test_Abs() public view {
        int256 a = -42;
        uint256 expected = 42;

        assertEq(signedMathHelper.abs(a), expected);

        a = 42;

        assertEq(signedMathHelper.abs(a), expected);
    }
}
