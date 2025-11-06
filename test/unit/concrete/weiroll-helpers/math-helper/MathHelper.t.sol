// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {MathHelper} from "src/weiroll-helpers/MathHelper.sol";

import {Unit_Concrete_Test} from "../../UnitConcrete.t.sol";

contract MathHelper_Unit_concrete_Test is Unit_Concrete_Test {
    MathHelper public mathHelper;

    function setUp() public virtual override {
        Unit_Concrete_Test.setUp();

        mathHelper = new MathHelper();
    }

    function test_Add() public view {
        uint256 a = 42;
        uint256 b = 58;
        uint256 expected = 100;

        assertEq(mathHelper.add(a, b), expected);
    }

    function test_Sub() public {
        uint256 a = 100;
        uint256 b = 58;
        uint256 expected = 42;

        assertEq(mathHelper.sub(a, b), expected);

        vm.expectRevert();
        mathHelper.sub(b, a);
    }

    function test_Mul() public view {
        uint256 a = 6;
        uint256 b = 7;
        uint256 expected = 42;

        assertEq(mathHelper.mul(a, b), expected);
    }

    function test_Div() public {
        uint256 a = 85;
        uint256 b = 2;
        uint256 expected = 42;

        assertEq(mathHelper.div(a, b), expected);

        vm.expectRevert();
        mathHelper.div(a, 0);
    }

    function test_CeilDiv() public {
        uint256 a = 85;
        uint256 b = 2;
        uint256 expected = 43;

        assertEq(mathHelper.ceilDiv(a, b), expected);

        vm.expectRevert();
        mathHelper.ceilDiv(a, 0);
    }

    function test_mulDiv() public {
        uint256 a = 21;
        uint256 b = 2;
        uint256 c = 5;
        uint256 expected = 8;

        assertEq(mathHelper.mulDiv(a, b, c), expected);

        vm.expectRevert();
        mathHelper.mulDiv(a, b, 0);
    }

    function test_ceilMulDiv() public {
        uint256 a = 21;
        uint256 b = 2;
        uint256 c = 5;
        uint256 expected = 9;

        assertEq(mathHelper.ceilMulDiv(a, b, c), expected);

        vm.expectRevert();
        mathHelper.ceilMulDiv(a, b, 0);
    }

    function test_Sqrt() public view {
        uint256 a = 1764;
        uint256 expected = 42;

        assertEq(mathHelper.sqrt(a), expected);
    }

    function test_Average() public view {
        uint256 a = 40;
        uint256 b = 44;
        uint256 expected = 42;

        assertEq(mathHelper.average(a, b), expected);
    }

    function test_Ternary() public view {
        uint256 a = 42;
        uint256 b = 84;

        assertEq(mathHelper.ternary(true, a, b), a);
        assertEq(mathHelper.ternary(false, a, b), b);
    }

    function test_Max() public view {
        uint256 a = 42;
        uint256 b = 84;

        assertEq(mathHelper.max(a, b), b);
    }

    function test_Min() public view {
        uint256 a = 42;
        uint256 b = 84;

        assertEq(mathHelper.min(a, b), a);
    }

    function test_Log2() public view {
        uint256 a = 1024;
        uint256 expected = 10;

        assertEq(mathHelper.log2(a), expected);

        assertEq(mathHelper.log2(0), 0);
    }

    function test_Log10() public view {
        uint256 a = 1000;
        uint256 expected = 3;

        assertEq(mathHelper.log10(a), expected);

        assertEq(mathHelper.log10(0), 0);
    }

    function test_Log256() public view {
        uint256 a = 65536;
        uint256 expected = 2;

        assertEq(mathHelper.log256(a), expected);

        assertEq(mathHelper.log256(0), 0);
    }

    function test_Eq() public view {
        uint256 a = 42;
        uint256 b = 42;
        uint256 c = 84;

        assertEq(mathHelper.eq(a, b), true);
        assertEq(mathHelper.eq(a, c), false);
    }

    function test_Lt() public view {
        uint256 a = 42;
        uint256 b = 42;
        uint256 c = 84;

        assertEq(mathHelper.lt(a, b), false);
        assertEq(mathHelper.lt(a, c), true);
        assertEq(mathHelper.lt(c, a), false);
    }

    function test_Lte() public view {
        uint256 a = 42;
        uint256 b = 42;
        uint256 c = 84;

        assertEq(mathHelper.lte(a, b), true);
        assertEq(mathHelper.lte(a, c), true);
        assertEq(mathHelper.lte(c, a), false);
    }

    function test_Gt() public view {
        uint256 a = 42;
        uint256 b = 42;
        uint256 c = 84;

        assertEq(mathHelper.gt(a, b), false);
        assertEq(mathHelper.gt(a, c), false);
        assertEq(mathHelper.gt(c, a), true);
    }

    function test_Gte() public view {
        uint256 a = 42;
        uint256 b = 42;
        uint256 c = 84;

        assertEq(mathHelper.gte(a, b), true);
        assertEq(mathHelper.gte(a, c), false);
        assertEq(mathHelper.gte(c, a), true);
    }

    function test_Uint128Max() public view {
        assertEq(mathHelper.uint128Max(), type(uint128).max);
    }

    function test_Uint256Max() public view {
        assertEq(mathHelper.uint256Max(), type(uint256).max);
    }

    function test_ScaleAmount_RevertWhen_DecimalsOutOfRange() public {
        uint8 oorDecimals = 78;

        vm.expectRevert(MathHelper.DecimalsOutOfRange.selector);
        mathHelper.scaleAmount(0, oorDecimals, 0);

        vm.expectRevert(MathHelper.DecimalsOutOfRange.selector);
        mathHelper.scaleAmount(0, 0, oorDecimals);
    }

    function test_ScaleAmount() public view {
        uint256 amount = 1_100_000;

        // Scaling up
        assertEq(mathHelper.scaleAmount(amount, 6, 18), 1_100_000_000_000_000_000);
        assertEq(mathHelper.scaleAmount(amount, 6, 8), 110_000_000);
        assertEq(mathHelper.scaleAmount(amount, 0, 18), 1_100_000_000_000_000_000_000_000);

        // Scaling down
        assertEq(mathHelper.scaleAmount(amount, 6, 1), 11);
        assertEq(mathHelper.scaleAmount(amount, 6, 0), 1);
        assertEq(mathHelper.scaleAmount(amount, 7, 1), 1);
        assertEq(mathHelper.scaleAmount(amount, 7, 0), 0);
        assertEq(mathHelper.scaleAmount(amount, 8, 1), 0);
    }
}
