# Deploy Makina Core

This README outlines the steps to deploy the Makina Core contracts.

## Environment setup

- Copy `.env.example` to `.env` and fill in the required RPC URLs, Etherscan API URLs, and API keys.
- Some networks are preconfigured in `foundry.toml` and only require the corresponding environment variables. More networks can be added following similar configuration.
- The commands below use a foundry keystore to specify the deployment wallet (`--account <keystore-name>`). For other options, refer to the [Foundry docs](https://getfoundry.sh/forge/reference/script/).
- Notation used in the commands:
  - `<keystore-name>` - the name of a Foundry keystore containing the deployer’s private key
  - `<network-alias>` - must match a network name declared in `foundry.toml`

## Hub Chain Deployments

Set the `HUB_INPUT_FILE` and `HUB_OUTPUT_FILE` values in your `.env` file to define the input and output JSON filenames, respectively. For example, for a deployment on Ethereum Mainnet, both of these files can be named `Mainnet.json`.

### Implementations IDs

Implementations IDs need to be provided for the various machine periphery modules implementations. See step 4 below.

### Shared contracts

1. Copy `script/deployments/inputs/hub-peripheries/TEMPLATE.json` to `script/deployments/inputs/hub-peripheries/{HUB_INPUT_FILENAME}` and fill in the required variables.

2. Run the following command to initiate the deployment. This will generate an output file at `script/deployments/outputs/hub-peripheries/{HUB_OUTPUT_FILENAME}` containing the deployed contract addresses.

```
forge script script/deployments/DeployHubPeriphery.s.sol --rpc-url <network-alias> --account <keychain-name> --slow --broadcast --verify -vvvv
```

Note: This script performs deterministic deployment based on the deployer wallet address via the [CreateX Factory contract](https://github.com/pcaversaccio/createx).

3. Run the following command to run contracts AccessManager setup. This script needs to be run from an address that has the `ADMIN_ROLE` in the `AccessManager` provided at step 1.

```
forge script script/deployments/SetupHubPeripheryAM.s.sol --rpc-url <network-alias> --account <keychain-name> --slow --broadcast -vvvv
```

4. Copy `script/deployments/inputs/implem-ids/TEMPLATE.json` to `script/deployments/inputs/implem-ids/{HUB_INPUT_FILENAME}` and fill in the required variables.

5. Run the following command to run Registry contract setup. This script needs to be run from an address that has the `INFRA_SETUP_ROLE` in the `AccessManager` provided at step 1.

```
forge script script/deployments/SetupHubPeripheryRegistry.s.sol --rpc-url <network-alias> --account <keychain-name> --slow --broadcast -vvvv
```

### Security Module instance

1. Copy `script/deployments/inputs/security-modules/TEMPLATE.json` to `script/deployments/inputs/security-modules/{HUB_INPUT_FILENAME}` and fill in the required variables.
2. Run the following command to initiate the deployment. This will generate an output file at `script/deployments/outputs/security-modules/{HUB_OUTPUT_FILENAME}` containing the deployed contract address.

```
forge script script/deployments/DeploySecurityModule.s.sol --rpc-url <network-alias> --account <keychain-name> --slow --broadcast --verify -vvvv
```

### Direct Depositor instance

1. Copy `script/deployments/inputs/depositors/direct-depositors/TEMPLATE.json` to `script/deployments/inputs/depositors/direct-depositors/{HUB_INPUT_FILENAME}` and fill in the required variables.
2. Run the following command to initiate the deployment. This will generate an output file at `script/deployments/outputs/depositors/direct-depositors/{HUB_OUTPUT_FILENAME}` containing the deployed contract address.

```
forge script script/deployments/DeployDirectDepositor.s.sol --rpc-url <network-alias> --account <keychain-name> --slow --broadcast --verify -vvvv
```

### Async Redeemer instance

1. Copy `script/deployments/inputs/redeemers/async-redeemers/TEMPLATE.json` to `script/deployments/inputs/redeemers/async-redeemers/{HUB_INPUT_FILENAME}` and fill in the required variables.
2. Run the following command to initiate the deployment. This will generate an output file at `script/deployments/outputs/redeemers/async-redeemers/{HUB_OUTPUT_FILENAME}` containing the deployed contract address.

```
forge script script/deployments/DeployAsyncRedeemer.s.sol --rpc-url <network-alias> --account <keychain-name> --slow --broadcast --verify -vvvv
```

### Watermark Fee Manager instance

1. Copy `script/deployments/inputs/fee-managers/watermark-fee-managers/TEMPLATE.json` to `script/deployments/inputs/fee-managers/watermark-fee-managers/{HUB_INPUT_FILENAME}` and fill in the required variables.
2. Run the following command to initiate the deployment. This will generate an output file at `script/deployments/outputs/fee-managers/watermark-fee-managers/{HUB_OUTPUT_FILENAME}` containing the deployed contract address.

```
forge script script/deployments/DeployWatermarkFeeManager.s.sol --rpc-url <network-alias> --account <keychain-name> --slow --broadcast --verify -vvvv
```

## Spoke Chain Deployments

### Shared contracts

1. Copy `script/deployments/inputs/spoke-peripheries/TEMPLATE.json` to `script/deployments/inputs/spoke-peripheries/{SPOKE_INPUT_FILENAME}` and fill in the required variables.
2. Run the following command to initiate the deployment. This will generate an output file at `script/deployments/outputs/spoke-peripheries/{SPOKE_OUTPUT_FILENAME}` containing the deployed contract addresses.

```
forge script script/deployments/DeploySpokePeriphery.s.sol --rpc-url <network-alias> --account <keychain-name> --slow --broadcast --verify -vvvv
```

Note: This script performs deterministic deployment based on the deployer wallet address via the [CreateX Factory contract](https://github.com/pcaversaccio/createx).
