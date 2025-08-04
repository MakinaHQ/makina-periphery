// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {IMakinaGovernable} from "@makina-core/interfaces/IMakinaGovernable.sol";
import {MachineShare} from "@makina-core/machine/MachineShare.sol";

import {IAsyncMachineRedeemer} from "src/interfaces/IAsyncMachineRedeemer.sol";
import {IMachinePeriphery} from "src/interfaces/IMachinePeriphery.sol";

import {Constants} from "../../../../utils/Constants.sol";

import {MachinePeriphery_Integration_Concrete_Test} from "../../machine-periphery/MachinePeriphery.t.sol";

contract AsyncMachineRedeemer_Integration_Concrete_Test is MachinePeriphery_Integration_Concrete_Test {
    IAsyncMachineRedeemer public asyncMachineRedeemer;

    address public machineDepositorAddr;

    function setUp() public virtual override {
        MachinePeriphery_Integration_Concrete_Test.setUp();

        vm.prank(dao);
        asyncMachineRedeemer = IAsyncMachineRedeemer(
            hubPeripheryFactory.createMachineRedeemer(
                ASYNC_REDEEM_MANAGER_IMPLEM_ID, abi.encode(Constants.DEFAULT_FINALIZATION_DELAY)
            )
        );

        machineDepositorAddr = makeAddr("machineDepositor");

        (machine,) =
            _deployMachine(address(accountingToken), machineDepositorAddr, address(asyncMachineRedeemer), address(0));
        machineShare = MachineShare(machine.shareToken());
    }

    modifier withMachine(address _machine) {
        vm.prank(address(hubPeripheryFactory));
        asyncMachineRedeemer.setMachine(_machine);

        _;
    }

    function _setRecoveryMode() internal {
        vm.prank(securityCouncil);
        machine.setRecoveryMode(true);
    }
}
