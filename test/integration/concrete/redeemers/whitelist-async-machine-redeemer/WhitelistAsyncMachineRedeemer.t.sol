// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {MachineShare} from "@makina-core/machine/MachineShare.sol";

import {IAsyncMachineRedeemer} from "src/interfaces/IAsyncMachineRedeemer.sol";
import {IWhitelist} from "src/interfaces/IWhitelist.sol";

import {Constants} from "../../../../utils/Constants.sol";
import {MachinePeriphery_Integration_Concrete_Test} from "../../machine-periphery/MachinePeriphery.t.sol";
import {AsyncMachineRedeemer_Integration_Concrete_Test} from "../async-machine-redeemer/AsyncMachineRedeemer.t.sol";

import {PreviewFinalizeRequests_Integration_Concrete_Test} from
    "../async-machine-redeemer/preview-finalize-requests/previewFinalizeRequests.t.sol";
import {ClaimAssets_Integration_Concrete_Test} from "../async-machine-redeemer/claim-assets/claimAssets.t.sol";
import {FinalizeRequests_Integration_Concrete_Test} from
    "../async-machine-redeemer/finalize-requests/finalizeRequests.t.sol";

abstract contract WhitelistAsyncMachineRedeemer_Integration_Concrete_Test is
    AsyncMachineRedeemer_Integration_Concrete_Test
{
    function setUp() public virtual override {
        MachinePeriphery_Integration_Concrete_Test.setUp();

        vm.prank(dao);
        asyncMachineRedeemer = IAsyncMachineRedeemer(
            hubPeripheryFactory.createMachineRedeemer(
                WHITELISTED_ASYNC_REDEEM_MANAGER_IMPLEM_ID, abi.encode(Constants.DEFAULT_FINALIZATION_DELAY)
            )
        );

        machineDepositorAddr = makeAddr("machineDepositor");

        (machine,) =
            _deployMachine(address(accountingToken), machineDepositorAddr, address(asyncMachineRedeemer), address(0));
        machineShare = MachineShare(machine.shareToken());
    }

    modifier withWhitelistedUser(address _user) {
        address[] memory users = new address[](1);
        users[0] = _user;

        vm.prank(dao);
        IWhitelist(address(asyncMachineRedeemer)).setWhitelistedUsers(users, true);

        _;
    }
}

contract PreviewFinalizeRequests_WhitelistAsyncMachineRedeemer_Integration_Concrete_Test is
    WhitelistAsyncMachineRedeemer_Integration_Concrete_Test,
    PreviewFinalizeRequests_Integration_Concrete_Test
{
    function setUp()
        public
        virtual
        override(WhitelistAsyncMachineRedeemer_Integration_Concrete_Test, PreviewFinalizeRequests_Integration_Concrete_Test)
    {
        WhitelistAsyncMachineRedeemer_Integration_Concrete_Test.setUp();

        vm.prank(dao);
        hubPeripheryFactory.setMachine(address(asyncMachineRedeemer), address(machine));

        address[] memory users = new address[](2);
        users[0] = user1;
        users[1] = user2;

        vm.prank(dao);
        IWhitelist(address(asyncMachineRedeemer)).setWhitelistedUsers(users, true);
    }
}

contract FinalizeRequests_WhitelistAsyncMachineRedeemer_Integration_Concrete_Test is
    WhitelistAsyncMachineRedeemer_Integration_Concrete_Test,
    FinalizeRequests_Integration_Concrete_Test
{
    function setUp()
        public
        virtual
        override(WhitelistAsyncMachineRedeemer_Integration_Concrete_Test, FinalizeRequests_Integration_Concrete_Test)
    {
        WhitelistAsyncMachineRedeemer_Integration_Concrete_Test.setUp();

        vm.prank(dao);
        hubPeripheryFactory.setMachine(address(asyncMachineRedeemer), address(machine));

        address[] memory users = new address[](2);
        users[0] = user1;
        users[1] = user2;

        vm.prank(dao);
        IWhitelist(address(asyncMachineRedeemer)).setWhitelistedUsers(users, true);
    }
}

contract ClaimAssets_WhitelistAsyncMachineRedeemer_Integration_Concrete_Test is
    WhitelistAsyncMachineRedeemer_Integration_Concrete_Test,
    ClaimAssets_Integration_Concrete_Test
{
    function setUp()
        public
        virtual
        override(WhitelistAsyncMachineRedeemer_Integration_Concrete_Test, ClaimAssets_Integration_Concrete_Test)
    {
        WhitelistAsyncMachineRedeemer_Integration_Concrete_Test.setUp();

        vm.prank(dao);
        hubPeripheryFactory.setMachine(address(asyncMachineRedeemer), address(machine));

        address[] memory users = new address[](2);
        users[0] = user1;
        users[1] = user2;

        vm.prank(dao);
        IWhitelist(address(asyncMachineRedeemer)).setWhitelistedUsers(users, true);
    }
}
