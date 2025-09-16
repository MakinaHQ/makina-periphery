# Makina Access Control

## Roles Permissions List

This is the list of role permissions in Makina Periphery contracts. These roles must be assigned to respective contracts at deployment.

### HubPeripheryRegistry

- `INFRA_SETUP_ROLE` (roleId `1`)
  - Can set address of HubPeripheryFactory.
  - Can set address of depositor Beacons.
  - Can set address of redeemer Beacons.
  - Can set address of fee manager Beacons.
  - Can set address of SecurityModule Beacon.

### HubPeripheryFactory

- `STRATEGY_DEPLOYMENT_ROLE` (roleId `2`)
  - Can deploy depositors.
  - Can deploy redeemers.
  - Can deploy fee managers.
  - Can deploy security modules.

### DirectDepositor

- **Risk Manager**
  - Can activate and deactivate whitelist.
  - Can add or remove users from the whitelist.

### AsyncRedeemManager

- **Mechanic**
  - Can finalize redemption requests, provided that the requests have reached their finalisation delay and that the machine is not in recovery mode.

- **Risk Manager**
  - Can activate and deactivate whitelist.
  - Can add or remove users from the whitelist.

- **Risk Manager Timelock**
  - Can set the request finalisation delay.

### WatermarkFeeManager

- `STRATEGY_COMPONENTS_SETUP_ROLE` (roleId `3`)
  - Can reset the share price watermark to a value below the current one.
  - Can set the fee rates.
  - Can define the allocation of fees to different receivers.

### SecurityModule

- **Security Council**
  - Can slash locked machine shares up to the maximum slashable amount.
  - Can re-enable locking after a slashing event.

- **Risk Manager Timelock**
  - Can set the cooldown duration.
  - Can set the maximum slashable ratio of machine share balance in the vault
  - Can set the minimum machine share balance that must remain in the vault after a slashing event.
