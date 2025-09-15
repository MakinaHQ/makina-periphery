// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {ICaliber} from "@makina-core/interfaces/ICaliber.sol";

/// @dev MockCaliber contract for testing use only
contract MockCaliber {
    event ParamsHash(bytes32 paramsHash);

    uint256 private _flPremium;

    function manageFlashLoan(ICaliber.Instruction calldata instruction, address token, uint256 amount) external {
        emit ParamsHash(keccak256(abi.encode(instruction, token, amount)));
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        IERC20(token).transfer(msg.sender, amount + _flPremium);
    }

    function setFlashloanPremium(uint256 flPremium) external {
        _flPremium = flPremium;
    }
}
