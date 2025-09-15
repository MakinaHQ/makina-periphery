// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {AccessManagedUpgradeable} from "@openzeppelin/contracts-upgradeable/access/manager/AccessManagedUpgradeable.sol";

import {ERC4626Oracle} from "../oracles/ERC4626Oracle.sol";
import {IMetaMorphoFactory} from "../interfaces/IMetaMorphoFactory.sol";
import {IMetaMorphoOracleFactory} from "../interfaces/IMetaMorphoOracleFactory.sol";

contract MetaMorphoOracleFactory is AccessManagedUpgradeable, IMetaMorphoOracleFactory {
    // @custom:storage-location erc7201:makina.storage.MetaMorphoOracleFactory
    struct MetaMorphoOracleFactoryStorage {
        mapping(address oracle => bool isOracle) _isOracle;
        mapping(address factory => bool isFactory) _isMorphoFactory;
    }

    // keccak256(abi.encode(uint256(keccak256("makina.storage.MetaMorphoOracleFactory")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant MetaMorphoOracleFactoryStorageLocation =
        0x8b272443f96f44d511b8bb6ad6efe08c8771f99b7e57f25c3f699349a99dca00;

    function _getMetaMorphoOracleFactoryStorage() internal pure returns (MetaMorphoOracleFactoryStorage storage $) {
        assembly {
            $.slot := MetaMorphoOracleFactoryStorageLocation
        }
    }

    constructor() {
        _disableInitializers();
    }

    function initialize(address _initialAuthority) external initializer {
        __AccessManaged_init(_initialAuthority);
    }

    /// @inheritdoc IMetaMorphoOracleFactory
    function isMorphoFactory(address morphoFactory) external view returns (bool) {
        MetaMorphoOracleFactoryStorage storage $ = _getMetaMorphoOracleFactoryStorage();
        return $._isMorphoFactory[morphoFactory];
    }

    /// @inheritdoc IMetaMorphoOracleFactory
    function isOracle(address oracle) external view returns (bool) {
        MetaMorphoOracleFactoryStorage storage $ = _getMetaMorphoOracleFactoryStorage();
        return $._isOracle[oracle];
    }

    /// @inheritdoc IMetaMorphoOracleFactory
    function setMorphoFactory(address morphoFactory, bool isFactory) external override restricted {
        MetaMorphoOracleFactoryStorage storage $ = _getMetaMorphoOracleFactoryStorage();
        $._isMorphoFactory[morphoFactory] = isFactory;
    }

    /// @inheritdoc IMetaMorphoOracleFactory
    function createMetaMorphoOracle(address factory, address metaMorphoVault, uint8 decimals)
        external
        override
        restricted
        returns (address)
    {
        MetaMorphoOracleFactoryStorage storage $ = _getMetaMorphoOracleFactoryStorage();

        if (!$._isMorphoFactory[factory]) {
            revert NotFactory();
        }

        // Check whether the vault to create an oracle for is verified by Morpho.
        if (!IMetaMorphoFactory(factory).isMetaMorpho(metaMorphoVault)) {
            revert NotMetaMorphoVault();
        }

        // Create the oracle.
        address oracle = address(new ERC4626Oracle(IERC4626(metaMorphoVault), decimals));
        $._isOracle[oracle] = true;

        emit MetaMorphoOracleCreated(oracle);

        return oracle;
    }
}
