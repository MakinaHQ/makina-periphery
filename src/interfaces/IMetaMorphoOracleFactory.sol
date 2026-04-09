// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IMetaMorphoOracleFactory {
    error NotMetaMorphoVault();

    error NotFactory();

    event MetaMorphoOracleCreated(address indexed oracle);

    /// @notice Factory => Whether this is a whitelisted Morpho factory.
    function isMorphoFactory(address morphoFactory) external view returns (bool isFactory);

    /// @notice Oracle => Whether this is an oracle instance deployed by this factory.
    function isOracle(address oracle) external view returns (bool);

    /// @notice Whitelist or unwhitelist a Morpho factory.
    /// @param morphoFactory The address of the Morpho factory.
    /// @param isFactory True to whitelist the factory, false to unwhitelist.
    function setMorphoFactory(address morphoFactory, bool isFactory) external;

    /// @notice Creates an oracle for the given MetaMorpho Vault.
    /// @param factory The factory used to create the MetaMorpho Vault.
    /// @param metaMorphoVault The Vault for which to create a wrapper oracle.
    /// @param decimals Decimals to use for the oracle price.
    function createMetaMorphoOracle(address factory, address metaMorphoVault, uint8 decimals) external returns (address);
}
