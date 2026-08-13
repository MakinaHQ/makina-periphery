// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

abstract contract SaltDomains {
    /// @dev FlashloanAggregator is non-upgradeable, so its salt domain is versioned.
    bytes32 internal constant FLASHLOAN_AGGREGATOR_SALT_DOMAIN = keccak256("makina.salt.FlashloanAggregator.v1.3.0");

    bytes32 internal constant PERIPHERY_REGISTRY_SALT_DOMAIN = keccak256("makina.salt.PeripheryRegistry");

    bytes32 internal constant PERIPHERY_FACTORY_SALT_DOMAIN = keccak256("makina.salt.PeripheryFactory");

    bytes32 internal constant DIRECT_DEPOSITOR_SALT_DOMAIN = keccak256("makina.salt.DirectDepositor");

    bytes32 internal constant ASYNC_REDEEMER_SALT_DOMAIN = keccak256("makina.salt.AsyncRedeemer");

    bytes32 internal constant ASYNC_REDEEMER_FEE_SALT_DOMAIN = keccak256("makina.salt.AsyncRedeemerFee");

    bytes32 internal constant WATERMARK_FEE_MANAGER_SALT_DOMAIN = keccak256("makina.salt.WatermarkFeeManager");

    bytes32 internal constant SECURITY_MODULE_SALT_DOMAIN = keccak256("makina.salt.SecurityModule");

    bytes32 internal constant META_MORPHO_ORACLE_FACTORY_SALT_DOMAIN = keccak256("makina.salt.MetaMorphoOracleFactory");

    bytes32 internal constant MACHINE_SHARE_ORACLE_SALT_DOMAIN = keccak256("makina.salt.MachineShareOracle");

    bytes32 internal constant MACHINE_SHARE_ORACLE_FACTORY_SALT_DOMAIN =
        keccak256("makina.salt.MachineShareOracleFactory");
}
