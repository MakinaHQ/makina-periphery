# Makina Periphery Specifications

## Machine Periphery Modules

Each newly deployed `Machine` instance requires a depositor, a redeemer, and a fee manager contract. The protocol provides a set of implementations for each component, allowing them to be combined modularly with any new machine depending on the strategy’s requirements.
Each implementation is assigned an implementation ID, which maps to a beacon in the `HubPeripheryRegistry`.

### Depositors

The Depositor contract is the contracts through which users deposit into the associated machine.

**DirectDepositor (ID = 1):** This implementation directly forwards deposit calls to the associated machine, with support for user whitelisting.

### Redeemers

The Redeemers contract is the contracts through which users redeem shares of the associated machine.

**AsyncRedeemer (ID = 1):** Implements ERC-721 to manage asynchronous redemption requests via a FIFO queue, with support for user whitelisting.

### Fee Managers

The fee manager is the contract that performs fee calculation, and dispatch them to designated receivers.

**WatermarkFeeManager (ID = 1):** Calculates both fixed fees (management fee + staking module fee) and a variable performance fee. A high watermark mechanism ensures performance fees are charged only when the current share price exceeds the stored watermark.

## Staking Module

The staking module serves as an insurance reserve, designed to mitigate losses in the event of a shortfall caused by incidents such as hacks, bad debt, or a depeg.

Machine shareholders can stake their shares in the staking module. In the event of a shortfall, the staked shares can be burned to cover losses.

In return, staking participants receive enhanced yields, distributed as a portion of the machine’s minted fee shares.

## Flashloan Aggregator

This contract provides flashloan functionality within a Caliber execution. When invoked by Caliber, the flashloan aggregator requests a loan from the specified protocol and forwards the borrowed funds to Caliber. Once Caliber has completed execution, it returns the funds to the flashloan aggregator, which then repays the loan.

## Access Control

Similarly to Makina Core contracts, contracts in this repository implement the [OpenZeppelin AccessManagerUpgradeable](https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/access/manager/AccessManagerUpgradeable.sol). The Makina protocol provides an instance of `AccessManagerUpgradeable` with addresses defined by the Makina DAO, but institutions that require it can deploy machines and periphery modules with their own `AccessManagerUpgradeable`. See [PERMISSIONS.md](https://github.com/makinaHQ/makina-periphery/blob/main/PERMISSIONS.md) for full list of permissions.

Roles used in makina periphery contracts are defined as follows:

- `ADMIN_ROLE` - roleId `0` - the Access Manager super admin. Can grant and revoke any role. Set by default in the Access Manager constructor.
- `STRATEGY_DEPLOYER_ROLE` - roleId `1` - the address allowed to deploy new periphery modules.
- `STRATEGY_CONFIG_ROLE` - roleId `2` - the address allowed to set the entities that manage strategies, whitelisted users where relevant, as well as the fee setup.
- `INFRA_CONFIG_ROLE` - roleId `3` - the address allowed to perform setup and maintenance on shared core contracts.
