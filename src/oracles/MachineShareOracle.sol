// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import {IHubCoreFactory} from "@makina-core/interfaces/IHubCoreFactory.sol";
import {IMachine} from "@makina-core/interfaces/IMachine.sol";
import {IOracleRegistry} from "@makina-core/interfaces/IOracleRegistry.sol";
import {IPreDepositVault} from "@makina-core/interfaces/IPreDepositVault.sol";
import {IHubCoreRegistry} from "@makina-core/interfaces/IHubCoreRegistry.sol";
import {DecimalsUtils} from "@makina-core/libraries/DecimalsUtils.sol";
import {MachineUtils} from "@makina-core/libraries/MachineUtils.sol";
import {MakinaContext} from "@makina-core/utils/MakinaContext.sol";

import {IMachineShareOracle} from "../interfaces/IMachineShareOracle.sol";
import {IShareTokenOwner} from "../interfaces/IShareTokenOwner.sol";
import {CoreErrors} from "../libraries/Errors.sol";

contract MachineShareOracle is MakinaContext, Initializable, IMachineShareOracle {
    using Math for uint256;

    // @custom:storage-location erc7201:makina.storage.MachineShareOracle
    struct MachineShareOracleStorage {
        address _shareOwner;
        bool _isShareOwnerPdv;
        uint8 _decimals;
        uint256 _scalingNumerator;
        uint256 _shareTokenDecimalsOffset;
        string _description;
    }

    // keccak256(abi.encode(uint256(keccak256("makina.storage.MachineShareOracle")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant MachineShareOracleStorageLocation =
        0x4f70fa92dc3700b8f04f54ea7fbeb33f50a8cec0cd9f676fee937dccebe28100;

    function _getMachineShareOracleStorage() internal pure returns (MachineShareOracleStorage storage $) {
        assembly {
            $.slot := MachineShareOracleStorageLocation
        }
    }

    constructor(address coreRegistry) MakinaContext(coreRegistry) {
        _disableInitializers();
    }

    /// @inheritdoc IMachineShareOracle
    function initialize(address _shareOwner, uint8 _decimals) external initializer {
        MachineShareOracleStorage storage $ = _getMachineShareOracleStorage();

        address coreFactory = IHubCoreRegistry(registry).coreFactory();
        if (IHubCoreFactory(coreFactory).isPreDepositVault(_shareOwner)) {
            if (IPreDepositVault(_shareOwner).migrated()) {
                revert CoreErrors.Migrated();
            }
            $._isShareOwnerPdv = true;
        } else if (!IHubCoreFactory(coreFactory).isMachine(_shareOwner)) {
            revert InvalidShareOwner();
        }

        $._shareOwner = _shareOwner;

        address shareToken = IShareTokenOwner(_shareOwner).shareToken();
        address accountingToken = IShareTokenOwner(_shareOwner).accountingToken();

        uint8 atDecimals = DecimalsUtils._getDecimals(accountingToken);
        if (_decimals < atDecimals) {
            revert CoreErrors.InvalidDecimals();
        }

        $._decimals = _decimals;
        $._scalingNumerator = 10 ** (_decimals - atDecimals);
        $._shareTokenDecimalsOffset = DecimalsUtils.SHARE_TOKEN_DECIMALS - atDecimals;
        $._description =
            string.concat(IERC20Metadata(shareToken).symbol(), " / ", IERC20Metadata(accountingToken).symbol());
    }

    /// @inheritdoc IMachineShareOracle
    function decimals() external view override returns (uint8) {
        return _getMachineShareOracleStorage()._decimals;
    }

    /// @inheritdoc IMachineShareOracle
    function description() external view override returns (string memory) {
        return _getMachineShareOracleStorage()._description;
    }

    /// @inheritdoc IMachineShareOracle
    function shareOwner() public view override returns (address) {
        MachineShareOracleStorage storage $ = _getMachineShareOracleStorage();
        return !$._isShareOwnerPdv || !IPreDepositVault($._shareOwner).migrated()
            ? $._shareOwner
            : IPreDepositVault($._shareOwner).machine();
    }

    /// @inheritdoc IMachineShareOracle
    function getSharePrice() external view override returns (uint256) {
        MachineShareOracleStorage storage $ = _getMachineShareOracleStorage();

        address shareToken = IShareTokenOwner($._shareOwner).shareToken();
        address accountingToken = IShareTokenOwner($._shareOwner).accountingToken();

        uint256 aum;
        if ($._isShareOwnerPdv) {
            if (IPreDepositVault($._shareOwner).migrated()) {
                aum = IMachine(IPreDepositVault($._shareOwner).machine()).lastTotalAum();
            } else {
                address depositToken = IPreDepositVault($._shareOwner).depositToken();
                uint256 dtbal = IERC20Metadata(depositToken).balanceOf($._shareOwner);
                uint256 price_d_a =
                    IOracleRegistry(IHubCoreRegistry(registry).oracleRegistry()).getPrice(depositToken, accountingToken);
                aum = dtbal.mulDiv(price_d_a, 10 ** DecimalsUtils._getDecimals(depositToken));
            }
        } else {
            aum = IMachine($._shareOwner).lastTotalAum();
        }

        uint256 supply = IERC20Metadata(shareToken).totalSupply();

        return $._scalingNumerator * MachineUtils.getSharePrice(aum, supply, $._shareTokenDecimalsOffset);
    }

    /// @inheritdoc IMachineShareOracle
    function notifyPdvMigration() external override {
        MachineShareOracleStorage storage $ = _getMachineShareOracleStorage();

        if (!$._isShareOwnerPdv) {
            revert CoreErrors.NotPreDepositVault();
        }

        address newShareOwner = IPreDepositVault($._shareOwner).machine();
        emit ShareOwnerMigrated($._shareOwner, newShareOwner);

        $._shareOwner = newShareOwner;
        $._isShareOwnerPdv = false;
    }
}
