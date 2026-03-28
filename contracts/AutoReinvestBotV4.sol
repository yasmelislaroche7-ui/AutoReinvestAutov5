// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// OpenZeppelin Contracts
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

// Uniswap V3 Interfaces
interface INonfungiblePositionManager is IERC721 {
    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    function collect(CollectParams calldata params) external returns (uint256 amount0, uint256 amount1);
    function positions(uint256 tokenId) external view returns (
        uint96 nonce,
        address operator,
        address token0,
        address token1,
        uint24 fee,
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity,
        uint256 feeGrowthInside0LastX128,
        uint256 feeGrowthInside1LastX128,
        uint128 tokensOwed0,
        uint128 tokensOwed1
    );
    function decreaseLiquidity(DecreaseLiquidityParams calldata params) external returns (uint256 amount0, uint256 amount1);
    function factory() external view returns (address);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
}

interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(ExactInputSingleParams calldata params) external returns (uint256 amountOut);
}

interface IUniswapV3Factory {
    function getPool(address tokenA, address tokenB, uint24 fee) external view returns (address pool);
}

interface ITimeStaking {
    function claimReward() external;
    function pendingReward(address user) external view returns (uint256);
}

interface IUniswapV3Pool {
    struct Slot0 {
        uint160 sqrtPriceX96;
        int24 tick;
        uint16 observationIndex;
        uint16 observationCardinality;
        uint16 observationCardinalityNext;
        uint16 feeProtocol;
        bool unlocked;
    }

    function slot0() external view returns (Slot0 memory);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function fee() external view returns (uint24);
}

// PERMIT2 INTERFACE
interface IPermit2 {
    struct PermitSingle {
        address token;
        uint160 amount;
        uint48 expiration;
        uint48 nonce;
    }

    struct SignatureTransferDetails {
        address to;
        uint160 requestedAmount;
    }

    function permitTransferFrom(
        PermitSingle calldata permit,
        SignatureTransferDetails calldata transferDetails,
        address owner,
        bytes calldata signature
    ) external;

    function approve(address token, address spender, uint160 amount) external;
}

// MULTICALL2 INTERFACE
interface IMulticall2 {
    struct Call {
        address target;
        bytes callData;
    }

    function multicall(Call[] calldata calls) external returns (bytes[] memory returnData);
    function tryMulticall(Call[] calldata calls) external returns (bool[] memory success, bytes[] memory returnData);
}

// WORLD APP PORTAL INTERFACE (ENTRYPOINTS REQUERIDOS)
interface IWorldAppPortal {
    function getContractName() external view returns (string memory);
    function getContractVersion() external view returns (string memory);
    function getSupportedOperations() external view returns (string[] memory);
}


// CONTRATO FINAL CON TODOS LOS COMPONENTES
contract AutoReinvestBotV4 is Ownable2Step, IERC721Receiver, EIP712, IWorldAppPortal {
    // Librerías
    using SafeERC20 for IERC20;
    using Address for address;

    // --- CONTRATOS EXTERNOS INMUTABLES WORLD CHAIN ---
    INonfungiblePositionManager public immutable positionManager;
    ISwapRouter public immutable swapRouter;
    ITimeStaking public immutable stakingContract;
    IUniswapV3Factory public immutable uniswapFactory;
    IPermit2 public immutable permit2;
    IMulticall2 public immutable multicall2;

    // --- DIRECCIONES OFICIALES WORLD CHAIN (HARDCODEADAS PARA ENTRYPOINTS) ---
    address public constant UNISWAP_FACTORY = 0x7a5028bda40e7b173c278c5342087826455ea25a;
    address public constant POSITION_MANAGER = 0xec12a9f9a09f50550686363766cc153d03c27b5e;
    address public constant SWAP_ROUTER = 0x091ad9e2e6e5ed44c1c66db50e49a601f9f36cf6;
    address public constant PERMIT2 = 0x000000000022d473030f116ddee9f6b43ac78ba3;
    address public constant MULTICALL2 = 0x0a22c04215c97e3f532f4ef30e0ad9458792dab9;

    // --- PARÁMETROS FIJOS ---
    uint256 public constant RESERVE_FEE_PCT = 2;
    uint256 public constant DISTRIBUTE_H2O_PCT = 40;
    uint256 public constant DISTRIBUTE_BTCH2O_PCT = 30;
    uint256 public constant REINVEST_PCT = 30;
    uint256 public constant PCT_DENOMINATOR = 100;
    uint256 public constant DEFAULT_SWAP_FEE = 3000;
    string public constant CONTRACT_NAME = "AutoReinvestBotV4";
    string public constant CONTRACT_VERSION = "1.0.0";

    // --- CONFIGURACIÓN FONDO DE RESERVA ---
    address[] public reserveTokens;
    mapping(address => bool) public isReserveToken;
    mapping(address => uint256) public minReserveBalance;
    mapping(address => uint256) public maxReserveBalance;
    mapping(address => uint256) public reserveFund;

    // --- GESTIÓN POSICIONES LP ---
    uint256[] public managedTokenIds;
    mapping(uint256 => bool) public isManagedPosition;
    mapping(uint256 => bool) public isPositionInRange;
    mapping(uint256 => address) public positionPool;

    // --- TOKENS ESPECÍFICOS ---
    address public immutable WLD;
    address public immutable H2O;
    address public immutable BTCH2O;

    // --- EIP712 PARA PERMIT2 ---
    bytes32 public constant PERMIT_TYPEHASH = keccak256(
        "PermitSingle(address token,uint160 amount,uint48 expiration,uint48 nonce)"
    );

    // --- EVENTOS ---
    event ReserveTokenAdded(address indexed token, uint256 minBalance, uint256 maxBalance);
    event ReserveTokenRemoved(address indexed token);
    event TokensDepositedToReserve(address indexed token, uint256 amount);
    event ReserveFundWithdrawn(address indexed token, uint256 amount);
    event PositionImported(uint256 indexed tokenId, bool inRange);
    event AllActivePositionsImported(uint256 totalImported);
    event PositionWithdrawn(uint256 indexed tokenId, address indexed recipient, bool wasInRange);
    event FeesCollected(uint256 indexed tokenId, uint256 amount0, uint256 amount1);
    event TokensSwapped(address indexed fromToken, address indexed toToken, uint256 amountIn, uint256 amountOut);
    event ReinvestmentExecuted(uint256 indexed tokenId, uint256 wldUsed, uint256 pairedTokenUsed);
    event ReinvestmentFailed(uint256 indexed tokenId);
    event Permit2ApprovalSet(address token, address spender, uint160 amount);
    event BatchOperationsExecuted(uint256 totalCalls, uint256 successfulCalls);


    // --- CONSTRUCTOR ---
    constructor(
        address _stakingContract,
        address _WLD,
        address _H2O,
        address _BTCH2O
    ) Ownable2Step(msg.sender) EIP712(CONTRACT_NAME, CONTRACT_VERSION) {
        // VALIDACIONES
        require(_stakingContract.isContract(), "STAKING_NO_CONTRATO");
        require(_WLD != address(0) && _H2O != address(0) && _BTCH2O != address(0), "TOKEN_CERO_INVALIDO");

        // ASIGNACIÓN CONTRATOS EXTERNOS (DIRECCIONES HARDCODEADAS OFICIALES)
        positionManager = INonfungiblePositionManager(POSITION_MANAGER);
        swapRouter = ISwapRouter(SWAP_ROUTER);
        stakingContract = ITimeStaking(_stakingContract);
        uniswapFactory = IUniswapV3Factory(UNISWAP_FACTORY);
        permit2 = IPermit2(PERMIT2);
        multicall2 = IMulticall2(MULTICALL2);

        // ASIGNACIÓN TOKENS
        WLD = _WLD;
        H2O = _H2O;
        BTCH2O = _BTCH2O;

        // AÑADIR TOKENS AL FONDO
        _addReserveTokenInternal(WLD, 1 * 10**18, 50 * 10**18);
        _addReserveTokenInternal(H2O, 0.5 * 10**18, 25 * 10**18);
        _addReserveTokenInternal(BTCH2O, 0.3 * 10**18, 15 * 10**18);
    }


    // --- ENTRYPOINTS PARA PORTAL DE WORLD APP ---
    function getContractName() external pure override returns (string memory) {
        return CONTRACT_NAME;
    }

    function getContractVersion() external pure override returns (string memory) {
        return CONTRACT_VERSION;
    }

    function getSupportedOperations() external pure override returns (string[] memory) {
        string[] memory operations = new string[](7);
        operations[0] = "Importar Posiciones LP";
        operations[1] = "Colectar y Procesar Fees";
        operations[2] = "Gestionar Fondo de Reserva";
        operations[3] = "Retirar Posiciones LP";
        operations[4] = "Aprobaciones con Permit2";
        operations[5] = "Operaciones Batch con Multicall2";
        operations[6] = "Reinvertir Fondos en LP";
        return operations;
    }


    // --- GESTIÓN PERMIT2 ---
    function setPermit2Approval(address token, uint160 amount) external onlyOwner {
        require(isReserveToken[token], "TOKEN_NO_PERMITIDO");
        permit2.approve(token, address(swapRouter), amount);
        emit Permit2ApprovalSet(token, address(swapRouter), amount);
    }

    function permitTransferWithSignature(
        IPermit2.PermitSingle calldata permit,
        IPermit2.SignatureTransferDetails calldata transferDetails,
        bytes calldata signature
    ) external onlyOwner {
        permit2.permitTransferFrom(permit, transferDetails, owner(), signature);
        reserveFund[permit.token] += transferDetails.requestedAmount;
        _enforceReserveLimits(permit.token);
        emit TokensDepositedToReserve(permit.token, transferDetails.requestedAmount);
    }


    // --- GESTIÓN MULTICALL2 ---
    function executeBatchOperations(IMulticall2.Call[] calldata calls) external onlyOwner returns (bytes[] memory returnData) {
        require(calls.length > 0, "NO_HAY_OPERACIONES");
        returnData = multicall2.multicall(calls);
        emit BatchOperationsExecuted(calls.length, returnData.length);
        return returnData;
    }

    function executeBatchOperationsWithFallback(IMulticall2.Call[] calldata calls) external onlyOwner returns (bool[] memory success, bytes[] memory returnData) {
        require(calls.length > 0, "NO_HAY_OPERACIONES");
        (success, returnData) = multicall2.tryMulticall(calls);
        emit BatchOperationsExecuted(calls.length, _countSuccessfulCalls(success));
        return (success, returnData);
    }

    function _countSuccessfulCalls(bool[] memory success) internal pure returns (uint256 count) {
        for (uint256 i = 0; i < success.length; i++) {
            if (success[i]) count++;
        }
    }


    // --- GESTIÓN FONDO DE RESERVA ---
    function addReserveToken(address token, uint256 minBal, uint256 maxBal) external onlyOwner {
        require(token != address(0), "TOKEN_CERO_INVALIDO");
        require(!isReserveToken[token], "TOKEN_YA_EN_FONDO");
        require(minBal < maxBal, "MIN_MAYOR_QUE_MAX");
        _addReserveTokenInternal(token, minBal, maxBal);
    }

    function removeReserveToken(address token) external onlyOwner {
        require(isReserveToken[token], "TOKEN_NO_EN_FONDO");
        for (uint256 i = 0; i < reserveTokens.length; i++) {
            if (reserveTokens[i] == token) {
                reserveTokens[i] = reserveTokens[reserveTokens.length - 1];
                reserveTokens.pop();
                break;
            }
        }
        isReserveToken[token] = false;
        delete minReserveBalance[token];
        delete maxReserveBalance[token];
        emit ReserveTokenRemoved(token);
    }

    function depositToReserve(address token, uint256 amount) external onlyOwner {
        require(isReserveToken[token], "TOKEN_NO_PERMITIDO");
        require(amount > 0, "CANTIDAD_CERO");
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        reserveFund[token] += amount;
        _enforceReserveLimits(token);
        emit TokensDepositedToReserve(token, amount);
    }

    function withdrawFromReserve(address token, uint256 amount) external onlyOwner {
        require(isReserveToken[token], "TOKEN_NO_PERMITIDO");
        require(amount > 0, "CANTIDAD_CERO");
        require(reserveFund[token] >= amount + minReserveBalance[token], "SALDO_BAJO_MINIMO");
        reserveFund[token] -= amount;
        IERC20(token).safeTransfer(owner(), amount);
        emit ReserveFundWithdrawn(token, amount);
    }

    function _addReserveTokenInternal(address token, uint256 minBal, uint256 maxBal) internal {
        reserveTokens.push(token);
        is
