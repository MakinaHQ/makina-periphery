// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.28;

import {IFlashLoanRecipient as BalancerV2FlashloanRecipient} from
    "@balancer-v2-interfaces/vault/IFlashLoanRecipient.sol";
import {IERC20 as BalancerIERC20} from "@balancer-v2-interfaces/solidity-utils/openzeppelin/IERC20.sol";
import {IVault as IVaultV2} from "@balancer-v2-interfaces/vault/IVault.sol";
import {IVault as IVaultV3} from "@balancer-v3-interfaces/vault/IVault.sol";

import {IMorpho} from "@morpho/interfaces/IMorpho.sol";
import {IMorphoFlashLoanCallback} from "@morpho/interfaces/IMorphoCallbacks.sol";

import {IERC3156FlashLender} from "@openzeppelin/contracts/interfaces/IERC3156FlashLender.sol";
import {IERC3156FlashBorrower} from "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";

import {IPool} from "@aave/interfaces/IPool.sol";
import {IPoolAddressesProvider} from "@aave/interfaces/IPoolAddressesProvider.sol";
import {IFlashLoanSimpleReceiver} from "@aave/misc/flashloan/interfaces/IFlashLoanSimpleReceiver.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {TransientSlot} from "@openzeppelin/contracts/utils/TransientSlot.sol";

import {ICaliber} from "@makina-core/interfaces/ICaliber.sol";
import {ICaliberFactory} from "@makina-core/interfaces/ICaliberFactory.sol";

import {IFlashloanAggregator} from "../interfaces/IFlashloanAggregator.sol";

contract FlashloanAggregator is
    IFlashloanAggregator,
    BalancerV2FlashloanRecipient,
    IMorphoFlashLoanCallback,
    IERC3156FlashBorrower,
    IFlashLoanSimpleReceiver
{
    using SafeERC20 for IERC20;
    using TransientSlot for *;

    /// @notice Hash of the user data we expect to receive in `onFlashLoan`.
    bytes32 public constant _EXPECTED_DATA_HASH_SLOT =
        0x82495b57f77c85cf8c0395fbfa4aaf855e2e402a9c6668de75d52c07a0b11300;

    /// @notice The address of the Caliber factory.
    address public immutable caliberFactory;

    /// @notice The address of the Balancer V2 pool.
    address public immutable balancerV2Pool;

    /// @notice The address of the Balancer V3 pool.
    address public immutable balancerV3Pool;

    /// @notice The address of the Morpho pool.
    address public immutable morphoPool;

    /// @notice The address of the DAI token.
    address public immutable dai;

    /// @notice The address of the Maker DSS Flash.
    address public immutable dssFlash;

    /// @notice The address of the Aave V3 pool.
    address public immutable aaveV3AddressProvider;

    /// @notice Modifier to check if the caller is a Caliber.
    modifier onlyCaliber() {
        if (!ICaliberFactory(caliberFactory).isCaliber(msg.sender)) {
            revert NotCaliber();
        }

        _;
    }

    /// @notice The constructor for the FlashloanAggregator.
    /// @param _caliberFactory The address of the Caliber factory.
    /// @param _balancerV2Pool The address of the Balancer V2 pool.
    /// @param _balancerV3Pool The address of the Balancer V3 pool.
    /// @param _morphoPool The address of the Morpho pool.
    /// @param _dssFlash The address of the Maker DSS Flash.
    constructor(
        address _caliberFactory,
        address _balancerV2Pool,
        address _balancerV3Pool,
        address _morphoPool,
        address _dssFlash,
        address _aaveV3AddressProvider,
        address _dai
    ) {
        caliberFactory = _caliberFactory;
        balancerV2Pool = _balancerV2Pool;
        balancerV3Pool = _balancerV3Pool;
        morphoPool = _morphoPool;
        dssFlash = _dssFlash;
        aaveV3AddressProvider = _aaveV3AddressProvider;
        dai = _dai;
    }

    /// @inheritdoc IFlashloanAggregator
    function requestFlashloan(FlashloanRequest calldata request) external override onlyCaliber {
        _dispatchFlashloanRequest(request);
    }

    /// @notice Function to dispatch the flashloan request to the correct provider.
    /// @param request The request for the flashloan.
    function _dispatchFlashloanRequest(FlashloanRequest calldata request) internal {
        if (request.provider == FlashloanProvider.BALANCER_V2) {
            _requestBalancerV2Flashloan(request);
        } else if (request.provider == FlashloanProvider.BALANCER_V3) {
            _requestBalancerV3Flashloan(request);
        } else if (request.provider == FlashloanProvider.MORPHO) {
            _requestMorphoFlashloan(request);
        } else if (request.provider == FlashloanProvider.DSS_FLASH) {
            _requestDssFlashloan(request);
        } else if (request.provider == FlashloanProvider.AAVE_V3) {
            _requestAaveV3Flashloan(request);
        }
    }

    /// @notice Internal function to clear the expected data hash.
    function _clearExpectedDataHash() internal {
        _EXPECTED_DATA_HASH_SLOT.asBytes32().tstore(bytes32(0));
    }

    /// @notice Internal function to set the expected data hash.
    /// @param data The data to set the expected data hash to.
    function _setExpectedDataHash(bytes memory data) internal {
        _EXPECTED_DATA_HASH_SLOT.asBytes32().tstore(keccak256(data));
    }

    /// @notice Internal function to check if the expected data hash is valid.
    /// @param data The data to check the expected data hash against.
    function _isValidExpectedDataHash(bytes memory data) internal view {
        if (_EXPECTED_DATA_HASH_SLOT.asBytes32().tload() != keccak256(data)) {
            revert InvalidUserDataHash();
        }
    }

    /// @notice Function to request a flashloan from Balancer V2.
    /// @param request The request for the flashloan.
    function _requestBalancerV2Flashloan(FlashloanRequest calldata request) internal {
        // Check that the Balancer V2 pool is not address(0).
        if (balancerV2Pool == address(0)) {
            revert BalancerV2PoolNotSet();
        }

        BalancerIERC20[] memory tokens = new BalancerIERC20[](1);
        tokens[0] = BalancerIERC20(request.token);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = request.amount;

        // Encode the callback data
        bytes memory data = abi.encode(msg.sender, request.instruction);

        // Set the expected data hash
        _setExpectedDataHash(data);
        // Request the flashloan
        IVaultV2(balancerV2Pool).flashLoan(this, tokens, amounts, data);
    }

    /// @notice Function to request a flashloan from Balancer V3.
    /// @param request The request for the flashloan.
    function _requestBalancerV3Flashloan(FlashloanRequest calldata request) internal {
        // Check that the Balancer V3 pool is not address(0).
        if (balancerV3Pool == address(0)) {
            revert BalancerV3PoolNotSet();
        }

        // Encode the callback data
        bytes memory data = abi.encodeWithSelector(
            FlashloanAggregator.balancerV3FlashloanCallback.selector,
            msg.sender,
            request.instruction,
            request.token,
            request.amount
        );

        // Set the expected data hash
        _setExpectedDataHash(data);
        // Unlock the vault
        IVaultV3(balancerV3Pool).unlock(data);
    }

    /// @notice Function to request a flashloan from Morpho.
    /// @param request The request for the flashloan.
    function _requestMorphoFlashloan(FlashloanRequest calldata request) internal {
        // Check that the Morpho pool is not address(0).
        if (morphoPool == address(0)) {
            revert MorphoPoolNotSet();
        }

        // Encode the callback data
        bytes memory data = abi.encode(request.token, msg.sender, request.instruction);

        // Set the expected data hash
        _setExpectedDataHash(data);
        // Request the flashloan
        IMorpho(morphoPool).flashLoan(request.token, request.amount, data);
    }

    /// @notice Function to request a flashloan from Maker DSS Flash.
    /// @param request The request for the flashloan.
    function _requestDssFlashloan(FlashloanRequest calldata request) internal {
        // Check that the Maker DSS Flash is not address(0).
        if (dssFlash == address(0)) {
            revert DssFlashNotSet();
        }
        // Check that the token is DAI.
        if (request.token != dai) {
            revert InvalidToken();
        }

        // Request the flashloan
        // No need to set the expected data hash as the flashloan passes the initiator over
        // and we can check it in `onFlashLoan`
        IERC3156FlashLender(dssFlash).flashLoan(
            this, request.token, request.amount, abi.encode(msg.sender, request.instruction)
        );
    }

    /// @notice Function to request a flashloan from Aave V3.
    /// @param request The request for the flashloan.
    function _requestAaveV3Flashloan(FlashloanRequest calldata request) internal {
        // Check that the Aave V3 address provider is not address(0).
        if (aaveV3AddressProvider == address(0)) {
            revert AaveV3PoolNotSet();
        }

        // Get the Aave V3 pool address
        IPool aaveV3Pool = IPool(IPoolAddressesProvider(aaveV3AddressProvider).getPool());

        // Encode the callback data
        bytes memory data = abi.encode(msg.sender, request.instruction);

        // Request the flashloan
        // No need to set the expected data hash as the flashloan passes the initiator over
        // and we can check it in `executeOperation`
        aaveV3Pool.flashLoanSimple(address(this), request.token, request.amount, data, 0);
    }

    /// @notice Catch-all function to handle the flashloan callback.
    /// @param caliber The address of the Caliber.
    /// @param instruction The instruction to execute.
    /// @param token The token to flashloan.
    /// @param amount The amount to flashloan.
    function _handleFlashloanCallback(
        address caliber,
        ICaliber.Instruction memory instruction,
        address token,
        uint256 amount
    ) internal {
        // Send the flashloan amount to the Caliber.
        IERC20(token).safeIncreaseAllowance(caliber, amount);
        // Calls `manageFlashLoan` on the Caliber.
        ICaliber(caliber).manageFlashLoan(instruction, token, amount);
    }

    /// @inheritdoc BalancerV2FlashloanRecipient
    function receiveFlashLoan(
        BalancerIERC20[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) external {
        // Check if the expected data hash is valid
        _isValidExpectedDataHash(userData);
        _clearExpectedDataHash();

        // Check if the caller is the Balancer V2 pool
        if (msg.sender != balancerV2Pool) {
            revert NotBalancerV2Pool();
        }
        // Check that exactly one token, amount, and fee amount is specified
        if (tokens.length != 1 || amounts.length != 1 || feeAmounts.length != 1) {
            revert InvalidParamsLength();
        }

        // Decode the user data
        (address caliber, ICaliber.Instruction memory instruction) =
            abi.decode(userData, (address, ICaliber.Instruction));

        // Handle the flashloan callback
        _handleFlashloanCallback(caliber, instruction, address(tokens[0]), amounts[0]);

        // Repay the flashloan
        IERC20(address(tokens[0])).safeTransfer(msg.sender, amounts[0] + feeAmounts[0]);
    }

    /// @notice Callback handler for Balancer V3 flashloan.
    function balancerV3FlashloanCallback(
        address caliber,
        ICaliber.Instruction calldata instruction,
        address token,
        uint256 amount
    ) external {
        // Check if the expected data hash is valid
        _isValidExpectedDataHash(msg.data);
        _clearExpectedDataHash();

        // Check if the caller is the Balancer V3 pool
        if (msg.sender != balancerV3Pool) {
            revert NotBalancerV3Pool();
        }

        // Send some tokens from the vault to this contract (taking a flash loan)
        IVaultV3(msg.sender).sendTo(IERC20(token), address(this), amount);

        // Handle the flashloan callback
        _handleFlashloanCallback(caliber, instruction, token, amount);

        // Repay the flashloan
        IERC20(token).safeTransfer(msg.sender, amount);

        // Settle the balance
        IVaultV3(msg.sender).settle(IERC20(token), amount);
    }

    /// @inheritdoc IMorphoFlashLoanCallback
    function onMorphoFlashLoan(uint256 assets, bytes calldata data) external {
        // Check if the expected data hash is valid
        _isValidExpectedDataHash(data);
        _clearExpectedDataHash();

        // Check if the caller is the Morpho pool
        if (msg.sender != morphoPool) {
            revert NotMorpho();
        }

        // Decode the data
        (address token, address caliber, ICaliber.Instruction memory instruction) =
            abi.decode(data, (address, address, ICaliber.Instruction));

        // Handle the flashloan callback
        _handleFlashloanCallback(caliber, instruction, token, assets);

        // Approve the Morpho pool to spend the tokens
        IERC20(token).safeIncreaseAllowance(morphoPool, assets);
    }

    /// @inheritdoc IERC3156FlashBorrower
    function onFlashLoan(address initiator, address token, uint256 amount, uint256 fee, bytes calldata data)
        external
        returns (bytes32)
    {
        // Check if the caller of this is the DSS Flash
        if (msg.sender != dssFlash) {
            revert NotDssFlash();
        }
        // Check that the initiator is this contract.
        if (initiator != address(this)) {
            revert NotRequested();
        }
        // Check that the fee is zero
        if (fee != 0) {
            revert InvalidFeeAmount();
        }

        // Decode the data
        (address caliber, ICaliber.Instruction memory instruction) = abi.decode(data, (address, ICaliber.Instruction));

        // Handle the flashloan callback
        _handleFlashloanCallback(caliber, instruction, token, amount);

        // Repay the flashloan
        IERC20(token).safeIncreaseAllowance(msg.sender, amount);

        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }

    /// @inheritdoc IFlashLoanSimpleReceiver
    function executeOperation(address asset, uint256 amount, uint256 premium, address initiator, bytes calldata params)
        external
        returns (bool)
    {
        // Get the Aave V3 pool address
        IPool aaveV3Pool = IPool(IPoolAddressesProvider(aaveV3AddressProvider).getPool());

        // Check if the caller of this is the Aave V3 pool
        if (msg.sender != address(aaveV3Pool)) {
            revert NotAaveV3Pool();
        }
        // Check that the initiator is this contract
        if (initiator != address(this)) {
            revert NotRequested();
        }

        // Decode the data
        (address caliber, ICaliber.Instruction memory instruction) = abi.decode(params, (address, ICaliber.Instruction));

        // Handle the flashloan callback
        _handleFlashloanCallback(caliber, instruction, asset, amount);

        // Repay the flashloan
        IERC20(asset).safeIncreaseAllowance(msg.sender, amount + premium);

        return true;
    }

    /// @inheritdoc IFlashLoanSimpleReceiver
    function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider) {
        return IPoolAddressesProvider(aaveV3AddressProvider);
    }

    /// @inheritdoc IFlashLoanSimpleReceiver
    function POOL() external view returns (IPool) {
        return IPool(IPoolAddressesProvider(aaveV3AddressProvider).getPool());
    }
}
