// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {AccessManagedUpgradeable} from "@openzeppelin/contracts-upgradeable/access/manager/AccessManagedUpgradeable.sol";

import {ERC4626Oracle} from "../oracles/ERC4626Oracle.sol";
import {MakinaPeripheryContext} from "../utils/MakinaPeripheryContext.sol";
import {IMetaMorphoV1_1Factory} from "../interfaces/IMetaMorphoV1_1Factory.sol";
import {IMetaMorphoOracleFactory} from "../interfaces/IMetaMorphoOracleFactory.sol";

contract MetaMorphoOracleFactory is AccessManagedUpgradeable, MakinaPeripheryContext, IMetaMorphoOracleFactory {
    // @custom:storage-location erc7201:makina.storage.MetaMorphoOracleFactory
    struct MetaMorphoOracleFactoryStorage {
        address _morphoRegistry;
        mapping(address oracle => bool isOracle) _isOracle;
    }

    // keccak256(abi.encode(uint256(keccak256("makina.storage.MetaMorphoOracleFactory")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant MetaMorphoOracleFactoryStorageLocation =
        0x8b272443f96f44d511b8bb6ad6efe08c8771f99b7e57f25c3f699349a99dca00;

    function _getMetaMorphoOracleFactoryStorage() internal pure returns (MetaMorphoOracleFactoryStorage storage $) {
        assembly {
            $.slot := MetaMorphoOracleFactoryStorageLocation
        }
    }

    constructor(address _peripheryRegistry) MakinaPeripheryContext(_peripheryRegistry) {
        _disableInitializers();
    }

    function initialize(address _initialAuthority) external initializer {
        __AccessManaged_init(_initialAuthority);
    }

    /// @inheritdoc IMetaMorphoOracleFactory
    function isOracle(address oracle) external view returns (bool) {
        MetaMorphoOracleFactoryStorage storage $ = _getMetaMorphoOracleFactoryStorage();
        return $._isOracle[oracle];
    }

    /// @inheritdoc IMetaMorphoOracleFactory
    function setMorphoRegistry(address morphoRegistry) external override restricted {
        MetaMorphoOracleFactoryStorage storage $ = _getMetaMorphoOracleFactoryStorage();
        $._morphoRegistry = morphoRegistry;
    }

    /// @inheritdoc IMetaMorphoOracleFactory
    function createMetaMorphoOracle(address metaMorphoVault, uint8 decimals)
        external
        override
        restricted
        returns (address)
    {
        MetaMorphoOracleFactoryStorage storage $ = _getMetaMorphoOracleFactoryStorage();

        // Check whether the vault to create an oracle for is verified by Morpho.
        if (!IMetaMorphoV1_1Factory($._morphoRegistry).isMetaMorpho(metaMorphoVault)) {
            revert NotMetaMorphoVault();
        }

        // Create the oracle.
        address oracle = address(new ERC4626Oracle(IERC4626(metaMorphoVault), decimals));
        $._isOracle[oracle] = true;

        emit MetaMorphoOracleCreated(oracle);

        return oracle;
    }
}
