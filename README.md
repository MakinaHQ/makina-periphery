# Makina Periphery Smart Contracts

This repository contains the periphery smart contracts of the Makina Protocol.

See `SPECIFICATION.md` and `PERMISSIONS.md` for more details.

## Contracts Overview

| Filename                      | Deployment chain | Description                                                                                      |
| ----------------------------- | ---------------- | ------------------------------------------------------------------------------------------------ |
| `HubPeripheryRegistry.sol`    | Hub              | Registry of factory and machine periphery module beacons.                                        |
| `HubPeripheryFactory.sol`     | Hub              | Hub factory for creation of machine periphery modules.                                           |
| `DirectDepositor.sol`         | Hub              | Synchronous Machine depositor contract.                                                          |
| `AsyncRedeemer.sol`           | Hub              | Asynchronous Machine redeemer contract.                                                          |
| `WatermarkFeeManager.sol`     | Hub              | Fee manager contract with a high-watermark mechanism for performance fee calculation.            |
| `SecurityModule.sol`          | Hub              | Security module for machine shares.                                                              |
| `SMCooldownReceipt.sol`       | Hub              | Receipt NFT for security module cooldown.                                                        |
| `FlashloanAggregator.sol`     | Hub + Spoke      | Standalone module used by calibers to execute flashLoan transactions through external protocols. |
| `MetaMorphoOracleFactory.sol` | Hub              | Factory for deploying Morpho vault oracles.                                                      |

## Installation

Follow [this link](https://book.getfoundry.sh/getting-started/installation) to install the Foundry toolchain.

## Submodules

Run below command to include/update all git submodules like forge-std, openzeppelin contracts etc (`lib/`)

```shell
git submodule update --init --recursive
```

## Dependencies

Run below command to include project dependencies like prettier and solhint (`node_modules/`)

```shell
yarn
```

### Build

Run below command to compile all other contracts

```shell
forge build
```

### Test

```shell
forge test
```

### Coverage

```shell
yarn coverage
```

### Format

```shell
forge fmt
```

### Lint

```shell
yarn lint
```
