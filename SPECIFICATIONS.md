# Makina Periphery Specifications

## Machine Periphery Modules

Each newly deployed `Machine` instance requires a depositor, a redeemer, and a fee manager contract. The protocol provides a set of implementations for each component, allowing them to be combined modularly with any new machine depending on the strategy’s requirements.
Each implementation is assigned an implementation ID, which maps to a beacon in the `HubPeripheryRegistry`.

### Depositors

A Depositor is a contract through which users deposit into the associated machine.

- **DirectDepositor (ID = 1001):** This implementation directly forwards deposit calls to the associated machine, with support for user whitelisting.

### Redeemers

A Redeemer is a contract through which users redeem shares of the associated machine.

- **AsyncRedeemer (ID = 2001):** Implements ERC-721 to manage asynchronous redemption requests via a FIFO queue, with support for user whitelisting.

- **AsyncRedeemerFee (ID = 2002):** Extends **AsyncRedeemer** with the support of a redeem fee.

### Fee Managers

The fee manager is the contract that performs fee calculation, and dispatches them to designated receivers.

- **WatermarkFeeManager (ID = 3001):** Calculates both fixed fees (management fee + security module fee) and a variable performance fee. A high watermark mechanism ensures performance fees are charged only when the current share price exceeds the stored watermark.

## Security Module

The security module serves as an insurance reserve, designed to mitigate losses in the event of a shortfall caused by incidents such as hacks, bad debt, or a depeg.

Machine shareholders can lock their shares in the security module. In the event of a shortfall, the locked shares can be burned to cover losses.

In return, locking participants receive enhanced yields, distributed as a portion of the machine’s minted fee shares.

## Flashloan Aggregator

This contract provides flashloan functionality within a Caliber execution. When invoked by Caliber, the flashloan aggregator requests a loan from the specified protocol and forwards the borrowed funds to Caliber. Once Caliber has completed execution, it returns the funds to the flashloan aggregator, which then repays the loan.

## Oracles

### MachineShareOracle

Chainlink-compatible price oracle exposing the price of one machine share token denominated in its associated accounting token. It supports both deployed machines and pre-deposit vaults, and transparently handles the migration of a pre-deposit vault to its associated machine.

After migration, anyone can call the permissionless `notifyPdvMigration` function to snapshot the new share owner.

### MachineShareOracleFactory

Factory deploying `MachineShareOracle` instances behind upgradeable beacon proxies. Each oracle is created for a single share owner (machine or pre-deposit vault) and registered in the factory.

### MetaMorphoOracleFactory

Factory deploying `ERC4626Oracle` instances wrapping MetaMorpho vaults. Oracle can be deployed only for vaults created by one of the whitelisted Morpho factories.

## Weiroll Helpers

Utility contracts callable as primitive operations from a Caliber's weiroll-encoded execution scripts:

- **BooleanHelper:** logical operators and boolean assertions.
- **Bytes32Helper:** comparison, selection, and indexed reads on `bytes32` values.
- **CastHelper:** safe casts between primitive types.
- **ContextHelper:** access to common EVM context values.
- **MathHelper:** unsigned arithmetic, comparisons, and decimal scaling utilities.
- **SignedMathHelper:** signed arithmetic utilities.
- **KeyValueStore:** per-Caliber key-value store for passing values between weiroll executions.

## Access Control

Similarly to Makina Core contracts, contracts in this repository implement the [OpenZeppelin AccessManagerUpgradeable](https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/access/manager/AccessManagerUpgradeable.sol). The Makina protocol provides an instance of `AccessManagerUpgradeable` with addresses defined by the Makina DAO, but institutions that require it can deploy machines and periphery modules with their own `AccessManagerUpgradeable`. See [PERMISSIONS.md](https://github.com/makinaHQ/makina-periphery/blob/main/PERMISSIONS.md) for full list of permissions.

Roles used in Makina Periphery contracts are a subset of those used in Makina Core contracts, and are defined as follows:

- `ADMIN_ROLE` - roleId `0` - Super admin of the Access Manager. Authorized to perform Access Manager configuration actions.
- `INFRA_CONFIG_ROLE` - roleId `1` - Authorized to configure shared periphery contracts.
- `STRATEGY_DEPLOYMENT_ROLE` - roleId `2` - Authorized to deploy new strategies.
- `STRATEGY_FEE_CONFIG_ROLE` - roleId `5` - Authorized to configure fee parameters in strategy periphery contracts.
- `INFRA_UPGRADE_ROLE` - roleId `6` - Authorized to upgrade proxies and beacons, and to register contracts in the periphery registry.
- `GUARDIAN_ROLE` - roleId `7` - Authorized to cancel operations scheduled with the other roles.
