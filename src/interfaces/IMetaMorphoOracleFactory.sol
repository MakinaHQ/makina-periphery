// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

interface IMetaMorphoOracleFactory {
    error NotMetaMorphoVault();

    event MetaMorphoOracleCreated(address indexed oracle);

    /// @notice Address => Whether this is an oracle deployed by this factory.
    function isOracle(address oracle) external view returns (bool);

    /// @notice Sets the Morpho Registry in the factory contract.
    /// @param morphoRegistry The address of the Morpho Registry.
    function setMorphoRegistry(address morphoRegistry) external;

    /// @notice Creates an oracle for the given MetaMorpho Vault.
    /// @param metaMorphoVault The Vault for which create a wrapper oracle.
    /// @param decimals Decimals to use for the oracle price.
    function createMetaMorphoOracle(address metaMorphoVault, uint8 decimals) external returns (address);
}
