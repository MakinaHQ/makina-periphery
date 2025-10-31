// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {Bytes32Helper} from "src/weiroll-helpers/Bytes32Helper.sol";

import {Unit_Concrete_Test} from "../../UnitConcrete.t.sol";

contract Bytes32Helper_Unit_concrete_Test is Unit_Concrete_Test {
    Bytes32Helper public bytes32Helper;

    function setUp() public virtual override {
        Unit_Concrete_Test.setUp();

        bytes32Helper = new Bytes32Helper();
    }

    function test_Eq() public view {
        bytes32 a = keccak256(abi.encodePacked("test1"));
        bytes32 b = keccak256(abi.encodePacked("test1"));
        bytes32 c = keccak256(abi.encodePacked("test2"));

        assertEq(bytes32Helper.eq(a, b), true);
        assertEq(bytes32Helper.eq(a, c), false);
    }

    function test_Ternary() public view {
        bytes32 a = keccak256(abi.encodePacked("test1"));
        bytes32 b = keccak256(abi.encodePacked("test2"));

        assertEq(bytes32Helper.ternary(true, a, b), a);
        assertEq(bytes32Helper.ternary(false, a, b), b);
    }

    function test_ArrayOf() public view {
        bytes32 a = bytes32(uint256(42));
        bytes32 b = bytes32(uint256(84));

        bytes32[] memory arr = bytes32Helper.arrayOf(a, b);
        assertEq(arr.length, 2);
        assertEq(arr[0], a);
        assertEq(arr[1], b);
    }

    function test_GetTupleWord() public {
        bytes32 element0 = keccak256(abi.encodePacked("element0"));
        bytes32 element1 = keccak256(abi.encodePacked("element1"));
        bytes32 element2 = keccak256(abi.encodePacked("element2"));

        bytes memory tuple = abi.encode(element0, element1, element2);

        assertEq(bytes32Helper.getTupleWord(tuple, 0), element0);
        assertEq(bytes32Helper.getTupleWord(tuple, 1), element1);
        assertEq(bytes32Helper.getTupleWord(tuple, 2), element2);

        vm.expectRevert(Bytes32Helper.IndexOutOfBounds.selector);
        bytes32Helper.getTupleWord(tuple, 3);
    }

    function test_GetArrayWord() public {
        bytes32 element0 = keccak256(abi.encodePacked("element0"));
        bytes32 element1 = keccak256(abi.encodePacked("element1"));
        bytes32 element2 = keccak256(abi.encodePacked("element2"));

        bytes32[] memory arr = new bytes32[](3);
        arr[0] = element0;
        arr[1] = element1;
        arr[2] = element2;

        assertEq(bytes32Helper.getArrayWord(arr, 0), element0);
        assertEq(bytes32Helper.getArrayWord(arr, 1), element1);
        assertEq(bytes32Helper.getArrayWord(arr, 2), element2);

        vm.expectRevert(Bytes32Helper.IndexOutOfBounds.selector);
        bytes32Helper.getArrayWord(arr, 3);
    }
}
