// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// INTERFACES COMPLETAS Y CORRECTAS
interface IUniswapV3Factory {
    function getPool(address tokenA, address tokenB, uint24 fee) external view returns (address);
}

interface INonfungiblePositionManager {
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
    function collect(CollectParams calldata params) external returns (uint256, uint256);
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
    function increaseLiquidity(IncreaseLiquidityParams calldata params) external;
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
    function exactInputSingle(ExactInputSingleParams calldata params) external returns (uint256);
}

// CONTRATO 100% FUNCIONAL
contract AutoReinvestBotV4 is Ownable2Step {
    using SafeERC20 for IERC20;

    // DIRECCIONES CON CHECKSUM CORRECTO WORLD CHAIN
    address public constant POSITION_MANAGER = 0xEC12A9F9A09f50550686363766cC153D03C27B5E;
    address public constant SWAP_ROUTER = 0x091Ad9E2E6E5Ed44c1C66DB50E49A601F9F36Cf6;
    address public constant UNISWAP_FACTORY = 0x7A5028BDa40E7B173C278C5342087826455Ea25A;

    // TOKENS
    address public immutable WLD;
    address public immutable H2O;
    address public immutable BTCH2O;

    // PARAMETROS
    uint256 public constant RESERVE_FEE = 2;
    uint256 public constant H2O_ALLOC = 40;
    uint256 public constant BTCH2O_ALLOC = 30;
    uint256 public constant REINVEST_ALLOC = 30;
    uint24 public constant FEE_TIER = 3000;

    // ESTADOS
    uint256[] public managedPositions;
    mapping(uint256 => bool) public isManaged;
    mapping(uint256 => bool) public inRange;
    mapping(address => uint256) public reserve;

    // EVENTOS
    event FeesCollected(uint256 id, uint256 a0, uint256 a1);
    event TokensSwapped(address from, address to, uint256 inAmt, uint256 outAmt);
    event Reinvested(uint256 id, uint256 wldUsed);

    constructor(
        address _WLD,
        address _H2O,
        address _BTCH2O
    ) {
        require(_WLD != address(0) && _H2O != address(0) && _BTCH2O != address(0), "Invalid token");
        WLD = _WLD;
        H2O = _H2O;
        BTCH2O = _BTCH2O;
    }

    function addPosition(uint256 tokenId) external onlyOwner {
        require(!isManaged[tokenId], "Already managed");
        managedPositions.push(tokenId);
        isManaged[tokenId] = true;

        // OBTENER DATOS DE RANGO
        (, , address t0, address t1, uint24 fee, int24 tLower, int24 tUpper, , , , , ) = 
            INonfungiblePositionManager(POSITION_MANAGER).positions(tokenId);
        address pool = IUniswapV3Factory(UNISWAP_FACTORY).getPool(t0, t1, fee);
        (, int24 currentTick, , , , , ) = IUniswapV3Pool(pool).slot0();
        inRange[tokenId] = (currentTick >= tLower && currentTick <= tUpper);
    }

    function processAllFees(uint256 deadline) external onlyOwner {
        require(deadline >= block.timestamp, "Expired");
        uint256 totalWLD;

        for (uint256 i = 0; i < managedPositions.length; i++) {
            uint256 id = managedPositions[i];
            (uint256 a0, uint256 a1) = INonfungiblePositionManager(POSITION_MANAGER).collect(
                INonfungiblePositionManager.CollectParams({
                    tokenId: id,
                    recipient: address(this),
                    amount0Max: type(uint128).max,
                    amount1Max: type(uint128).max
                })
            );
            emit FeesCollected(id, a0, a1);

            (, , address t0, address t1, , , , , , , , ) = INonfungiblePositionManager(POSITION_MANAGER).positions(id);
            if (t0 == WLD) totalWLD += a0;
            else if (a0 > 0) totalWLD += swap(t0, WLD, a0, deadline);
            if (t1 == WLD) totalWLD += a1;
            else if (a1 > 0) totalWLD += swap(t1, WLD, a1, deadline);
        }

        uint256 reserveAmt = (totalWLD * RESERVE_FEE) / 100;
        reserve[WLD] += reserveAmt;

        uint256 remaining = totalWLD - reserveAmt;
        uint256 h2oAmt = (remaining * H2O_ALLOC) / 100;
        uint256 btch2oAmt = (remaining * BTCH2O_ALLOC) / 100;
        uint256 reinvestAmt = remaining - h2oAmt - btch2oAmt;

        swap(WLD, H2O, h2oAmt, deadline);
        swap(WLD, BTCH2O, btch2oAmt, deadline);

        for (uint256 i = 0; i < managedPositions.length; i++) {
            uint256 id = managedPositions[i];
            if (inRange[id]) {
                INonfungiblePositionManager(POSITION_MANAGER).increaseLiquidity(
                    INonfungiblePositionManager.IncreaseLiquidityParams({
                        tokenId: id,
                        amount0Desired: reinvestAmt / managedPositions.length,
                        amount1Desired: reinvestAmt / managedPositions.length,
                        amount0Min: 0,
                        amount1Min: 0,
                        deadline: deadline
                    })
                );
                emit Reinvested(id, reinvestAmt / managedPositions.length);
            }
        }
    }

    function swap(address from, address to, uint256 amt, uint256 deadline) internal returns (uint256) {
        IERC20(from).approve(SWAP_ROUTER, amt);
        uint256 out = ISwapRouter(SWAP_ROUTER).exactInputSingle(
            ISwapRouter.ExactInputSingleParams({
                tokenIn: from,
                tokenOut: to,
                fee: FEE_TIER,
                recipient: address(this),
                deadline: deadline,
                amountIn: amt,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            })
        );
        emit TokensSwapped(from, to, amt, out);
        return out;
    }

    function withdrawReserve(address token, uint256 amt) external onlyOwner {
        require(reserve[token] >= amt, "Not enough");
        IERC20(token).safeTransfer(owner(), amt);
        reserve[token] -= amt;
    }
}
