// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// DEPENDENCIAS OPENZEPPELIN
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

// INTERFACES UNISWAP V3
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
    function token0() external view returns (address);
    function token1() external view returns (address);
    function slot0() external view returns (
        uint160 sqrtPriceX96,
        int24 tick,
        uint16 observationIndex,
        uint16 observationCardinality,
        uint16 observationCardinalityNext,
        uint16 feeProtocol,
        bool unlocked
    );
}

// CONTRATO PRINCIPAL
contract AutoReinvestBotV4 is Ownable2Step {
    using SafeERC20 for IERC20;
    using Address for address;

    // DIRECCIONES FIJAS WORLD CHAIN
    address public constant POSITION_MANAGER = 0xec12a9f9a09f50550686363766cc153d03c27b5e;
    address public constant SWAP_ROUTER = 0x091ad9e2e6e5ed44c1c66db50e49a601f9f36cf6;
    address public constant UNISWAP_FACTORY = 0x7a5028bda40e7b173c278c5342087826455ea25a;

    // TOKENS CONFIGURABLES
    address public immutable WLD;
    address public immutable H2O;
    address public immutable BTCH2O;

    // PARAMETROS DE DISTRIBUCION
    uint256 public constant RESERVE_FEE = 2;     // 2%
    uint256 public constant H2O_ALLOC = 40;     // 40%
    uint256 public constant BTCH2O_ALLOC = 30;   // 30%
    uint256 public constant REINVEST_ALLOC = 30; // 30%
    uint256 public constant FEE_TIER = 3000;     // 0.3%

    // ESTADOS
    uint256[] public managedTokenIds;
    mapping(uint256 => bool) public isManaged;
    mapping(uint256 => bool) public inRange;
    mapping(address => uint256) public reserveBalance;
    mapping(address => uint256) public minReserve;
    mapping(address => uint256) public maxReserve;
    address[] public reserveTokens;

    // EVENTOS
    event FeesCollected(uint256 tokenId, uint256 amount0, uint256 amount1);
    event TokensSwapped(address from, address to, uint256 amountIn, uint256 amountOut);
    event Reinvested(uint256 tokenId, uint256 wldAmount, uint256 pairedAmount);

    constructor(
        address _WLD,
        address _H2O,
        address _BTCH2O
    ) {
        require(_WLD != address(0) && _H2O != address(0) && _BTCH2O != address(0), "Invalid token address");
        WLD = _WLD;
        H2O = _H2O;
        BTCH2O = _BTCH2O;

        // AGREGAR TOKENS A RESERVA
        reserveTokens.push(_WLD);
        reserveTokens.push(_H2O);
        reserveTokens.push(_BTCH2O);
        minReserve[_WLD] = 1 ether;
        maxReserve[_WLD] = 50 ether;
        minReserve[_H2O] = 1 ether;
        maxReserve[_H2O] = 50 ether;
        minReserve[_BTCH2O] = 1 ether;
        maxReserve[_BTCH2O] = 50 ether;
    }

    // AGREGAR POSICION GESTIONADA
    function addManagedPosition(uint256 tokenId) external onlyOwner {
        require(!isManaged[tokenId], "Position already managed");
        managedTokenIds.push(tokenId);
        isManaged[tokenId] = true;

        // VERIFICAR RANGO
        (, , address token0, address token1, uint24 fee, int24 tickLower, int24 tickUpper, , , , , ) = 
            INonfungiblePositionManager(POSITION_MANAGER).positions(tokenId);
        (, int24 currentTick, , , , , ) = IUniswapV3Pool(
            UNISWAP_FACTORY.getPool(token0, token1, fee)
        ).slot0();
        inRange[tokenId] = (currentTick >= tickLower && currentTick <= tickUpper);
    }

    // COLECCIONAR Y PROCESAR
    function processFees(uint256[] calldata tokenIds, uint256 deadline) external onlyOwner {
        require(tokenIds.length > 0, "No positions to process");
        require(deadline >= block.timestamp, "Deadline expired");

        uint256 totalWLD;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 id = tokenIds[i];
            require(isManaged[id], "Not managed");

            // COLECTAR FEES
            (uint256 amt0, uint256 amt1) = INonfungiblePositionManager(POSITION_MANAGER).collect(
                INonfungiblePositionManager.CollectParams({
                    tokenId: id,
                    recipient: address(this),
                    amount0Max: type(uint128).max,
                    amount1Max: type(uint128).max
                })
            );
            emit FeesCollected(id, amt0, amt1);

            // CONVERTIR A WLD
            (, , address t0, address t1, , , , , , , , ) = INonfungiblePositionManager(POSITION_MANAGER).positions(id);
            if (t0 == WLD) totalWLD += amt0;
            else if (amt0 > 0) totalWLD += swap(t0, WLD, amt0, deadline);
            if (t1 == WLD) totalWLD += amt1;
            else if (amt1 > 0) totalWLD += swap(t1, WLD, amt1, deadline);
        }

        // APLICAR COMISION
        uint256 reserveAmount = (totalWLD * RESERVE_FEE) / 100;
        reserveBalance[WLD] += reserveAmount;
        require(reserveBalance[WLD] <= maxReserve[WLD], "Reserve over max");

        uint256 remaining = totalWLD - reserveAmount;
        uint256 h2oAmt = (remaining * H2O_ALLOC) / 100;
        uint256 btch2oAmt = (remaining * BTCH2O_ALLOC) / 100;
        uint256 reinvestAmt = (remaining * REINVEST_ALLOC) / 100;

        // CONVERTIR A H2O Y BTCH2O
        if (h2oAmt > 0) swap(WLD, H2O, h2oAmt, deadline);
        if (btch2oAmt > 0) swap(WLD, BTCH2O, btch2oAmt, deadline);

        // REINVERTIR
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 id = tokenIds[i];
            if (inRange[id]) {
                (, , address t0, address t1, uint24 fee, , , , , , , ) = INonfungiblePositionManager(POSITION_MANAGER).positions(id);
                address paired = UNISWAP_FACTORY.getPool(t0, t1, fee);
                (, int24 tick, , , , , ) = IUniswapV3Pool(paired).slot0();
                if (tick >= tickLower && tick <= tickUpper) {
                    INonfungiblePositionManager(POSITION_MANAGER).increaseLiquidity(
                        INonfungiblePositionManager.IncreaseLiquidityParams({
                            tokenId: id,
                            amount0Desired: reinvestAmt,
                            amount1Desired: reinvestAmt,
                            amount0Min: 0,
                            amount1Min: 0,
                            deadline: deadline
                        })
                    );
                    emit Reinvested(id, reinvestAmt, 0);
                }
            }
        }
    }

    // FUNCION DE SWAP
    function swap(address from, address to, uint256 amount, uint256 deadline) internal returns (uint256) {
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

    // GESTION DE RESERVAS
    function setReserveLimits(address token, uint256 min, uint256 max) external onlyOwner {
        require(token != address(0), "Invalid token");
        minReserve[token] = min;
        maxReserve[token] = max;
    }

    function depositToReserve(address token, uint256 amount) external onlyOwner {
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        reserveBalance[token] += amount;
        require(reserveBalance[token] <= maxReserve[token], "Over max reserve");
    }

    function withdrawFromReserve(address token, uint256 amount) external onlyOwner {
        require(reserveBalance[token] >= amount + minReserve[token], "Below min reserve");
        reserveBalance[token] -= amount;
        IERC20(token).transfer(owner(), amount);
    }
}
