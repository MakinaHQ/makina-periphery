// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {KeyValueStore} from "src/weiroll-helpers/KeyValueStore.sol";

import {Unit_Concrete_Test} from "../../UnitConcrete.t.sol";

contract KeyValueStore_Unit_concrete_Test is Unit_Concrete_Test {
    KeyValueStore public keyValueStore;

    address public caliberAddr;

    function setUp() public virtual override {
        Unit_Concrete_Test.setUp();

        caliberAddr = makeAddr("caliber");

        keyValueStore = new KeyValueStore(caliberAddr);
    }

    function test_Set_RevertWhen_NotCaliber() public {
        vm.expectRevert(KeyValueStore.NotOwner.selector);
        keyValueStore.set(bytes32(0), bytes32(0));
    }

    function test_SetAndGetUint256() public {
        bytes32 key = keccak256(abi.encodePacked("testKey"));
        bytes32 value = bytes32(uint256(42));

        vm.prank(caliberAddr);
        keyValueStore.set(key, value);
        bytes32 storedValue = keyValueStore.get(key);

        assertEq(storedValue, value);
    }

    function test_SetAndGetAddress() public {
        bytes32 key = keccak256(abi.encodePacked("testKey"));
        bytes32 value = bytes32(uint256(uint160(address(0x123))));

        vm.prank(caliberAddr);
        keyValueStore.set(key, value);

        assertEq(keyValueStore.get(key), value);
    }

    function test_Reset_RevertWhen_NotCaliber() public {
        vm.expectRevert(KeyValueStore.NotOwner.selector);
        keyValueStore.reset(bytes32(0));
    }

    function test_Reset() public {
        bytes32 key = keccak256(abi.encodePacked("testKey"));
        bytes32 value = bytes32(uint256(100));

        vm.startPrank(caliberAddr);
        keyValueStore.set(key, value);
        keyValueStore.reset(key);
        vm.stopPrank();

        assertEq(keyValueStore.get(key), bytes32(0));
    }
}
