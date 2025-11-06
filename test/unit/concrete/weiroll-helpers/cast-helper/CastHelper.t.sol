// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {CastHelper} from "src/weiroll-helpers/CastHelper.sol";

import {Unit_Concrete_Test} from "../../UnitConcrete.t.sol";

contract CastHelper_Unit_concrete_Test is Unit_Concrete_Test {
    CastHelper public castHelper;

    function setUp() public virtual override {
        Unit_Concrete_Test.setUp();

        castHelper = new CastHelper();
    }

    function test_Int256ToUint256() public view {
        int256 a = 42;
        uint256 b = 42;

        assertEq(castHelper.int256ToUint256(a), b);
    }

    function test_Uint256ToInt256() public view {
        uint256 a = 42;
        int256 b = 42;

        assertEq(castHelper.uint256ToInt256(a), b);
    }

    function test_BytesToString() public view {
        bytes memory a = "test string";
        string memory b = "test string";

        assertEq(castHelper.bytesToString(a), b);
    }
}
