// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {IAccessManaged} from "@openzeppelin/contracts/access/manager/IAccessManaged.sol";

import {DecimalsUtils} from "@makina-core/libraries/DecimalsUtils.sol";

import {MockERC20} from "@makina-core-test/mocks/MockERC20.sol";

import {Errors} from "src/libraries/Errors.sol";
import {IHubPeripheryFactory} from "src/interfaces/IHubPeripheryFactory.sol";
import {IStakingModule} from "src/interfaces/IStakingModule.sol";

import {HubPeripheryFactory_Integration_Concrete_Test} from "../HubPeripheryFactory.t.sol";

contract CreateStakingModule_Integration_Concrete_Test is HubPeripheryFactory_Integration_Concrete_Test {
    function test_RevertWhen_CallerWithoutRole() public {
        vm.expectRevert(abi.encodeWithSelector(IAccessManaged.AccessManagedUnauthorized.selector, address(this)));
        hubPeripheryFactory.createStakingModule(
            IStakingModule.StakingModuleInitParams({
                machineShare: address(0),
                initialCooldownDuration: 0,
                initialMaxSlashableBps: 0,
                initialMinBalanceAfterSlash: 0
            })
        );
    }

    function test_RevertWhen_InvalidValue() public {
        vm.expectRevert(Errors.MaxBpsValueExceeded.selector);
        vm.prank(dao);
        hubPeripheryFactory.createStakingModule(
            IStakingModule.StakingModuleInitParams({
                machineShare: address(0),
                initialCooldownDuration: 0,
                initialMaxSlashableBps: 10_001, // > 100%
                initialMinBalanceAfterSlash: 0
            })
        );
    }

    function test_CreateStakingModule() public {
        MockERC20 machineShare = new MockERC20("Machine Share", "MSHARE", DecimalsUtils.SHARE_TOKEN_DECIMALS);

        vm.expectEmit(false, false, false, false, address(hubPeripheryFactory));
        emit IHubPeripheryFactory.StakingModuleCreated(address(0));
        vm.prank(dao);
        address _stakingModule = hubPeripheryFactory.createStakingModule(
            IStakingModule.StakingModuleInitParams({
                machineShare: address(machineShare),
                initialCooldownDuration: 0,
                initialMaxSlashableBps: 0,
                initialMinBalanceAfterSlash: 0
            })
        );

        assertTrue(hubPeripheryFactory.isStakingModule(_stakingModule));
    }
}
