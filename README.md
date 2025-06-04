# Makina Periphery Smart Contracts

This repository contains the periphery smart contracts of the Makina Protocol.

## Contracts Overview

| Filename                   | Deployment chain | Description                                                                                      |
| -------------------------- | ---------------- | ------------------------------------------------------------------------------------------------ |
| `HubPeripheryRegistry.sol` | Hub              | Stores addresses of factory and beacons for core periphery components of the protocol.           |
| `HubPeripheryFactory.sol`  | Hub              | Hub factory for creation of machine managers.                                                    |
| `FlashloanAggregator.sol`  | Hub + Spoke      | Standalone module used by calibers to execute flashLoan transactions through external protocols. |

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
