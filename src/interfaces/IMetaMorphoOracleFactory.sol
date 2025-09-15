// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface IMetaMorphoOracleFactory {
    error NotMetaMorphoVault();

    error NotFactory();

    event MetaMorphoOracleCreated(address indexed oracle);

    /// @notice Address => Whether this is a trusted Morpho factory.
    /// @param morphoFactory The Morpho factory address to check.
    /// @return isFactory True if the factory is trusted, false otherwise.
    function isMorphoFactory(address morphoFactory) external view returns (bool isFactory);

    /// @notice Address => Whether this is an oracle deployed by this factory.
    /// @param oracle The oracle address to check.
    function isOracle(address oracle) external view returns (bool);

    /// @notice Sets the Morpho Registry in the factory contract.
    /// @param morphoFactory The address of the Morpho Registry.
    /// @param isFactory Flags the factory as trusted or not.
    function setMorphoFactory(address morphoFactory, bool isFactory) external;

    /// @notice Creates an oracle for the given MetaMorpho Vault.
    /// @param factory The factory used to create the MetaMorpho Vault.
    /// @param metaMorphoVault The Vault for which to create a wrapper oracle.
    /// @param decimals Decimals to use for the oracle price.
    function createMetaMorphoOracle(address factory, address metaMorphoVault, uint8 decimals)
        external
        returns (address);
}
