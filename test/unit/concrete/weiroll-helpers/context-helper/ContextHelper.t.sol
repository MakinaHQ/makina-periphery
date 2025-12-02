// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {ContextHelper} from "src/weiroll-helpers/ContextHelper.sol";

import {Unit_Concrete_Test} from "../../UnitConcrete.t.sol";

contract ContextHelper_Unit_concrete_Test is Unit_Concrete_Test {
    ContextHelper public contextHelper;

    function setUp() public virtual override {
        Unit_Concrete_Test.setUp();

        contextHelper = new ContextHelper();
    }

    function test_BlockTimestamp() public view {
        uint256 timestamp = contextHelper.blockTimestamp();
        assertEq(timestamp, block.timestamp);
    }

    function test_BlockNumber() public view {
        uint256 number = contextHelper.blockNumber();
        assertEq(number, block.number);
    }

    function test_MsgSender() public view {
        address sender = contextHelper.msgSender();
        assertEq(sender, address(this));
    }

    function test_Balance() public {
        uint256 bal = 12 ether;
        deal(address(this), bal);

        uint256 balance = contextHelper.balance(address(this));
        assertEq(balance, bal);
    }
}
