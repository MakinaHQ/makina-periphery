# Deploy Makina Periphery

This README outlines the steps to deploy the Makina Periphery contracts.

## Environment setup

- Copy `.env.example` to `.env` and fill in the required RPC URLs and the Etherscan API key.
- Some networks are preconfigured in `foundry.toml` and only require the corresponding environment variables. More networks can be added following similar configuration.
- Notation used in the commands:
  - `<wallet-options>` - the flags specifying the deployer wallet, e.g. `--account <keystore-name>` for a Foundry keystore. For other options, refer to the [Foundry docs](https://getfoundry.sh/forge/reference/script/)
  - `<network-alias>` - must match a network name declared in `foundry.toml`
- Each script documents its env vars in its NatSpec header.

## Hub Chain Deployments

Set the `HUB_PERIPHERY_INPUT_FILENAME` and `HUB_PERIPHERY_OUTPUT_FILENAME` values in your `.env` file to define the input and output JSON filenames, respectively. For example, for a deployment on Ethereum Mainnet, both of these files can be named `Mainnet.json`.

### Shared contracts

1. Copy `script/deploy/inputs/hub-peripheries/TEMPLATE.json` to `script/deploy/inputs/hub-peripheries/{HUB_PERIPHERY_INPUT_FILENAME}` and fill in the required variables.
2. Run the following command to initiate the deployment. This will generate an output file at `script/deploy/outputs/hub-peripheries/{HUB_PERIPHERY_OUTPUT_FILENAME}` containing the deployed contract addresses.

```shell
forge script script/deploy/DeployHubPeriphery.s.sol --rpc-url <network-alias> <wallet-options> --slow --broadcast --verify -vvvv
```

Note: This script performs deterministic deployment based on the deployer wallet address via the [CreateX Factory contract](https://github.com/pcaversaccio/createx). Implementation contracts already deployed by the same wallet are reused, and the script fails before broadcasting when a deterministic address is already occupied.

### Setup

The deployed contracts are governed by the `AccessManager` named in the input file, so wiring them is restricted. The setup scripts below either broadcast the calls from an account holding the required role, or run in view mode for the role holder to submit them.

#### View mode

Set `VIEW_MODE=true` to log each call's target and calldata, alongside its `AccessManager.schedule` wrapper for roles with an execution delay, instead of broadcasting. No `<wallet-options>` are needed. The setting applies to the setup scripts and to the strategy instance scripts below. Leave the variable unset (or `false`) to broadcast.

3. Run the following command to set the `AccessManager` function roles of the deployed contracts. Every call requires the `ADMIN_ROLE`.

```shell
VIEW_MODE=true forge script script/deploy/SetupHubPeripheryAM.s.sol --rpc-url <network-alias> -vvvv
```

4. Copy `script/deploy/inputs/implem-ids/TEMPLATE.json` to `script/deploy/inputs/implem-ids/{HUB_PERIPHERY_INPUT_FILENAME}` and fill in the implementation ids of the machine periphery components.

5. Run the following command to wire the `HubPeripheryRegistry`: the periphery factory, the security module beacon and the component beacons under their implementation ids. Every call requires the `INFRA_UPGRADE_ROLE` once step 3 has run, the `ADMIN_ROLE` otherwise.

```shell
VIEW_MODE=true forge script script/deploy/SetupHubPeripheryRegistry.s.sol --rpc-url <network-alias> -vvvv
```

### Strategy instances

In addition to `HUB_PERIPHERY_INPUT_FILENAME` and `HUB_PERIPHERY_OUTPUT_FILENAME` set above for shared contracts deployments, set the `HUB_STRAT_INPUT_FILENAME` and `HUB_STRAT_OUTPUT_FILENAME` values in your `.env` file.

The factory functions creating machine periphery components are restricted to the `STRATEGY_DEPLOYMENT_ROLE`. The scripts below broadcast from the deployer wallet, or run in view mode as described above: no output file is written then, and `HUB_STRAT_OUTPUT_FILENAME` can be left unset.

#### Security Module instance

1. Copy `script/deploy/inputs/security-modules/TEMPLATE.json` to `script/deploy/inputs/security-modules/{HUB_STRAT_INPUT_FILENAME}` and fill in the required variables.
2. Run the following command to initiate the deployment. This will generate an output file at `script/deploy/outputs/security-modules/{HUB_STRAT_OUTPUT_FILENAME}` containing the deployed contract address.

```shell
forge script script/deploy/DeploySecurityModule.s.sol --rpc-url <network-alias> <wallet-options> --slow --broadcast --verify -vvvv
```

#### Direct Depositor instance

1. Copy `script/deploy/inputs/depositors/direct-depositors/TEMPLATE.json` to `script/deploy/inputs/depositors/direct-depositors/{HUB_STRAT_INPUT_FILENAME}` and fill in the required variables.
2. Run the following command to initiate the deployment. This will generate an output file at `script/deploy/outputs/depositors/direct-depositors/{HUB_STRAT_OUTPUT_FILENAME}` containing the deployed contract address.

```shell
forge script script/deploy/DeployDirectDepositor.s.sol --rpc-url <network-alias> <wallet-options> --slow --broadcast --verify -vvvv
```

#### Async Redeemer instance

1. Copy `script/deploy/inputs/redeemers/async-redeemers/TEMPLATE.json` to `script/deploy/inputs/redeemers/async-redeemers/{HUB_STRAT_INPUT_FILENAME}` and fill in the required variables.
2. Run the following command to initiate the deployment. This will generate an output file at `script/deploy/outputs/redeemers/async-redeemers/{HUB_STRAT_OUTPUT_FILENAME}` containing the deployed contract address.

```shell
forge script script/deploy/DeployAsyncRedeemer.s.sol --rpc-url <network-alias> <wallet-options> --slow --broadcast --verify -vvvv
```

#### Async Redeemer Fee instance

1. Copy `script/deploy/inputs/redeemers/async-redeemer-fees/TEMPLATE.json` to `script/deploy/inputs/redeemers/async-redeemer-fees/{HUB_STRAT_INPUT_FILENAME}` and fill in the required variables.
2. Run the following command to initiate the deployment. This will generate an output file at `script/deploy/outputs/redeemers/async-redeemer-fees/{HUB_STRAT_OUTPUT_FILENAME}` containing the deployed contract address.

```shell
forge script script/deploy/DeployAsyncRedeemerFee.s.sol --rpc-url <network-alias> <wallet-options> --slow --broadcast --verify -vvvv
```

#### Watermark Fee Manager instance

1. Copy `script/deploy/inputs/fee-managers/watermark-fee-managers/TEMPLATE.json` to `script/deploy/inputs/fee-managers/watermark-fee-managers/{HUB_STRAT_INPUT_FILENAME}` and fill in the required variables.
2. Run the following command to initiate the deployment. This will generate an output file at `script/deploy/outputs/fee-managers/watermark-fee-managers/{HUB_STRAT_OUTPUT_FILENAME}` containing the deployed contract address.

```shell
forge script script/deploy/DeployWatermarkFeeManager.s.sol --rpc-url <network-alias> <wallet-options> --slow --broadcast --verify -vvvv
```

A non-zero `securityModule` in the input file is wired to the created fee manager with `HubPeripheryFactory.setSecurityModule`, right after the creation in broadcast mode. In view mode the script logs a reminder instead, as the fee manager address is only known once the creation is submitted.

## Spoke Chain Deployments

Set the `SPOKE_PERIPHERY_INPUT_FILENAME` and `SPOKE_PERIPHERY_OUTPUT_FILENAME` values in your `.env` file to define the input and output JSON filenames, respectively.

### Shared contracts

1. Copy `script/deploy/inputs/spoke-peripheries/TEMPLATE.json` to `script/deploy/inputs/spoke-peripheries/{SPOKE_PERIPHERY_INPUT_FILENAME}` and fill in the required variables.
2. Run the following command to initiate the deployment. This will generate an output file at `script/deploy/outputs/spoke-peripheries/{SPOKE_PERIPHERY_OUTPUT_FILENAME}` containing the deployed contract address.

```shell
forge script script/deploy/DeploySpokePeriphery.s.sol --rpc-url <network-alias> <wallet-options> --slow --broadcast --verify -vvvv
```

Note: Same as for hub chain shared contracts deployment, this script performs deterministic deployment based on the deployer wallet address via the [CreateX Factory contract](https://github.com/pcaversaccio/createx).

### Aggregator addresses

A hub periphery is deployed with plain salts. A spoke periphery's `FlashloanAggregator` salt also mixes in the hub chain id of its instance, read from the spoke core's `CaliberMailbox` beacon, so the spoke core must be wired beforehand. Each instance thus gets its own aggregator address, the same on every chain for a given deployer wallet, and a chain hosting a hub and spokes of other instances holds one aggregator per instance. A spoke of a foreign instance needs nothing more than its own `spokeCoreRegistry` in the input file.
