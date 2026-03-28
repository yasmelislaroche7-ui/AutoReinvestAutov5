// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// OpenZeppelin Contracts
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

// Uniswap V3 Interfaces
interface INonfungiblePositionManager {
    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
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
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
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

interface IUniswapV3Pool {
    function slot0() external view returns (
        uint160 sqrtPriceX96,
        int24 tick,
        uint16 observationIndex,
        uint16 observationCardinality,
        uint16 observationCardinalityNext,
        uint16 feeProtocol,
        bool unlocked
    );
    function token0() external view returns (address);
    function token1() external view returns (address);
    function fee() external view returns (uint24);
}

interface ITimeStaking {
    function claimReward() external;
    function pendingReward(address user) external view returns (uint256);
}

// CONTRATO PRINCIPAL
contract AutoReinvestBotV4 is Ownable2Step, EIP712, IERC721Receiver {
    using Address for address;
    using SafeERC20 for IERC20;

    // CONTRATOS EXTERNOS INMUTABLES (WORLD CHAIN)
    address public immutable UNISWAP_FACTORY = 0x7a5028bda40e7b173c278c5342087826455ea25a;
    address public immutable POSITION_MANAGER = 0xec12a9f9a09f50550686363766cc153d03c27b5e;
    address public immutable SWAP_ROUTER = 0x091ad9e2e6e5ed44c1c66db50e49a601f9f36cf6;
    address public immutable PERMIT2 = 0x000000000022d473030f116ddee9f6b43ac78ba3;
    address public immutable MULTICALL2 = 0x0a22c04215c97e3f532f4ef30e0ad9458792dab9;
    address public immutable STAKING_CONTRACT;

    // TOKENS
    address public immutable WLD;
    address public immutable H2O;
    address public immutable BTCH2O;

    // PARÁMETROS FIJOS
    uint256 public constant RESERVE_FEE = 2; // 2%
    uint256 public constant H2O_PCT = 40;    // 40%
    uint256 public constant BTCH2O_PCT = 30; // 30%
    uint256 public constant REINVEST_PCT = 30; // 30%
    uint256 public constant FEE_TIER = 3000; // 0.3%

    // ESTADOS
    uint256[] public managedTokenIds;
    mapping(uint256 => bool) public isManaged;
    mapping(uint256 => bool) public inRange;
    mapping(address => uint256) public reserveFund;
    mapping(address => uint256) public minReserve;
    mapping(address => uint256) public maxReserve;
    address[] public reserveTokens;

    // EVENTOS
    event FeesCollected(uint256 tokenId, uint256 amount0, uint256 amount1);
    event TokensSwapped(address from, address to, uint256 amountIn, uint256 amountOut);
    event Reinvested(uint256 tokenId, uint256 wldUsed, uint256 pairedUsed);
    event ReserveUpdated(address token, uint256 amount);

    constructor(
        address _stakingContract,
        address _WLD,
        address _H2O,
        address _BTCH2O
    ) EIP712("AutoReinvestBotV4", "1.0.0") {
        require(_stakingContract.isContract(), "No es contrato");
        require(_WLD != address(0) && _H2O != address(0) && _BTCH2O != address(0), "Token cero");

        STAKING_CONTRACT = _stakingContract;
        WLD = _WLD;
        H2O = _H2O;
        BTCH2O = _BTCH2O;
    }

    // RECEPCIÓN DE NFTs UNISWAP
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        require(operator == address(this) || from == owner(), "No autorizado");
        require(msg.sender == POSITION_MANAGER, "Solo Uniswap V3");

        managedTokenIds.push(tokenId);
        isManaged[tokenId] = true;

        // VERIFICAR RANGO
        (, , address token0, address token1, uint24 fee, int24 tickLower, int24 tickUpper, , , , , ) = 
            INonfungiblePositionManager(POSITION_MANAGER).positions(tokenId);
        (uint160 sqrtPriceX96, int24 currentTick, , , , , ) = IUniswapV3Pool(
            UNISWAP_FACTORY.getPool(token0, token1, fee)
        ).slot0();
        inRange[tokenId] = (currentTick >= tickLower && currentTick <= tickUpper);

        emit PositionAdded(tokenId, inRange[tokenId]);
        return IERC721Receiver.onERC721Received.selector;
    }

    // COLECCIONAR FEES
    function collectAndProcess(uint256[] calldata tokenIds, uint256 deadline) external onlyOwner {
        require(tokenIds.length > 0, "Sin posiciones");
        require(deadline >= block.timestamp, "Expirado");

        uint256 totalWLD;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 id = tokenIds[i];
            require(isManaged[id], "No gestionada");

            // COLECTAR FEES
            (uint256 amount0, uint256 amount1) = INonfungiblePositionManager(POSITION_MANAGER).collect(
                INonfungiblePositionManager.CollectParams({
                    tokenId: id,
                    recipient: address(this),
                    amount0Max: type(uint128).max,
                    amount1Max: type(uint128).max
                })
            );
            emit FeesCollected(id, amount0, amount1);

            // OBTENER TOKENS DEL POOL
            (address token0, address token1, uint24 feeTier) = _getPoolData(id);
            uint256 wldAmt = 0;

            if (token0 == WLD) wldAmt = amount0;
            else if (amount0 > 0) wldAmt = _swap(token0, WLD, amount0, deadline);

            if (token1 == WLD) wldAmt += amount1;
            else if (amount1 > 0) wldAmt += _swap(token1, WLD, amount1, deadline);

            totalWLD += wldAmt;
        }

        // APLICAR COMISIÓN
        uint256 reserveAmt = (totalWLD * RESERVE_FEE) / 100;
        reserveFund[WLD] += reserveAmt;
        emit ReserveUpdated(WLD, reserveAmt);

        uint256 restante = totalWLD - reserveAmt;
        uint256 h2oAmt = (restante * H2O_PCT) / 100;
        uint256 btch2oAmt = (restante * BTCH2O_PCT) / 100;
        uint256 reinvertir = (restante * REINVEST_PCT) / 100;

        // CONVERTIR Y DEPOSITAR
        if (h2oAmt > 0) {
            uint256 h2oSwap = _swap(WLD, H2O, h2oAmt, deadline);
            reserveFund[H2O] += h2oSwap;
        }

        if (btch2oAmt > 0) {
            uint256 btch2oSwap = _swap(WLD, BTCH2O, btch2oAmt, deadline);
            reserveFund[BTCH2O] += btch2oSwap;
        }

        // REINVERTIR EN POSICIONES
        for (uint256 i = 0; i < managedTokenIds.length; i++) {
            uint256 id = managedTokenIds[i];
            if (inRange[id]) {
                _reinvertir(id, reinvertir);
            }
        }
    }

    function _getPoolData(uint256 tokenId) internal view returns (address token0, address token1, uint24 fee) {
        (, , token0, token1, fee, , , , , , , ) = INonfungiblePositionManager(POSITION_MANAGER).positions(tokenId);
    }

    function _swap(address from, address to, uint256 amount, uint256 deadline) internal returns (uint256) {
        require(from != to, "Mismo token");
        IERC20(from).approve(SWAP_ROUTER, amount);

        uint256 out = ISwapRouter(SWAP_ROUTER).exactInputSingle(
            ISwapRouter.ExactInputSingleParams({
                tokenIn: from,
                tokenOut: to,
                fee: FEE_TIER,
                recipient: address(this),
                deadline: deadline,
                amountIn: amount,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            })
        );
        emit TokensSwapped(from, to, amount, out);
        return out;
    }

    function _reinvertir(uint256 tokenId, uint256 cantidad) internal {
        (, , address t0, address t1, , , , , , , , ) = INonfungiblePositionManager(POSITION_MANAGER).positions(tokenId);
        address paired = t0 == WLD ? t1 : t0;

        uint256 swapAmt = cantidad / 2;
        uint256 wldAmt = cantidad - swapAmt;

        uint256 pairedAmt = _swap(WLD, paired, swapAmt, block.timestamp);

        INonfungiblePositionManager(POSITION_MANAGER).increaseLiquidity(
            INonfungiblePositionManager.IncreaseLiquidityParams({
                tokenId: tokenId,
                amount0Desired: t0 == WLD ? wldAmt : pairedAmt,
                amount1Desired: t1 == WLD ? wldAmt : pairedAmt,
                amount0Min: 0,
                amount1Min: 0,
                deadline: block.timestamp
            })
        );
        emit Reinvested(tokenId, wldAmt, pairedAmt);
    }

    // GESTIÓN DE RESERVAS
    function addReserveToken(address token, uint256 min, uint256 max) external onlyOwner {
        require(!tokenExists[token], "Ya existe");
        reserveTokens.push(token);
        tokenExists[token] = true;
        minReserve[token] = min;
        maxReserve[token] = max;
        emit ReserveAdded(token, min, max);
    }

    function depositar(address token, uint256 amount) external onlyOwner {
        require(tokenExists[token], "No permitido");
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        reserveFund[token] += amount;
        _checkLimits(token);
    }

    function retirar(address token, uint256 amount) external onlyOwner {
        require(reserveFund[token] >= amount + minReserve[token], "Debajo del mínimo");
        reserveFund[token] -= amount;
        IERC20(token).transfer(owner(), amount);
        emit ReserveWithdrawn(token, amount);
    }

    function _checkLimits(address token) internal {
        if (reserveFund[token] > maxReserve[token]) {
            uint256 exceso = reserveFund[token] - maxReserve[token];
            reserveFund[token] = maxReserve[token];
            IERC20(token).transfer(owner(), exceso);
            emit ReserveWithdrawn(token, exceso);
        }
    }

    // INTERFAZ ERC721RECEIVER
    function onERC721Received(address, address from, uint256 tokenId, bytes calldata) external override returns (bytes4) {
        require(from == owner() || msg.sender == POSITION_MANAGER, "No autorizado");
        require(!isManaged[tokenId], "Ya gestionada");

        managedTokenIds.push(tokenId);
        isManaged[tokenId] = true;

        (, , address t0, address t1, uint24 fee, int24 tl, int24 tu, , , , , ) = POSITION_MANAGER.positions(tokenId);
        (uint160 sqrt, int24 tick, , , , , ) = IUniswapV3Pool(FACTORY.getPool(t0, t1, fee)).slot0();
        inRange[tokenId] = (tick >= tl && tick <= tu);

        emit PositionAdded(tokenId, inRange[tokenId]);
        return this.onERC721Received.selector;
    }
}
