// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface INonfungiblePositionManager {
    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }
    function collect(CollectParams calldata params) external returns (uint256, uint256);
    function positions(uint256 tokenId) external view returns (
        uint96, address, address, address, uint24, int24, int24, uint128, uint256, uint256, uint128, uint128
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
    function exactInputSingle(ExactInputSingleParams calldata params) external returns (uint256);
}

contract AutoReinvestBotV4 is Ownable2Step {
    using SafeERC20 for IERC20;

    // DIRECCIONES CONTRATOS WORLD CHAIN
    address public constant POSITION_MANAGER = 0xec12a9f9a09f50550686363766cc153d03c27b5e;
    address public constant SWAP_ROUTER = 0x091ad9e2e6e5ed44c1c66db50e49a601f9f36cf6;
    address public constant UNISWAP_FACTORY = 0x7a5028bda40e7b173c278c5342087826455ea25a;

    // TOKENS
    address public immutable WLD;
    address public immutable H2O;
    address public immutable BTCH2O;

    // PARAMETROS
    uint256 public constant RESERVE_FEE = 2;
    uint256 public constant H2O_PCT = 40;
    uint256 public constant BTCH2O_PCT = 30;
    uint256 public constant REINVEST_PCT = 30;
    uint256 public constant FEE_TIER = 3000;

    // ESTADOS
    uint256[] public managedTokens;
    mapping(uint256 => bool) public isManaged;
    mapping(uint256 => bool) public inRange;
    mapping(address => uint256) public reserveFund;

    // EVENTOS
    event FeesCollected(uint256 tokenId, uint256 amt0, uint256 amt1);
    event TokensSwapped(address from, address to, uint256 inAmt, uint256 outAmt);
    event Reinvested(uint256 tokenId, uint256 wldUsed);

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
        managedTokens.push(tokenId);
        isManaged[tokenId] = true;

        // CHECK RANGE
        (, , address t0, address t1, uint24 fee, int24 tLower, int24 tUpper, , , , , , ) = 
            INonfungiblePositionManager(POSITION_MANAGER).positions(tokenId);
        (, int24 currentTick, , , , , ) = IUniswapV3Pool(
            UNISWAP_FACTORY.getPool(t0, t1, fee)
        ).slot0();
        inRange[tokenId] = (currentTick >= tLower && currentTick <= tUpper);
    }

    function collectAndProcess(uint256[] calldata tokenIds, uint256 deadline) external onlyOwner {
        require(tokenIds.length > 0, "No positions");
        require(deadline >= block.timestamp, "Expired");

        uint256 totalWLD;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 id = tokenIds[i];
            require(isManaged[id], "Not managed");

            (uint256 amt0, uint256 amt1) = INonfungiblePositionManager(POSITION_MANAGER).collect(
                INonfungiblePositionManager.CollectParams({
                    tokenId: id,
                    recipient: address(this),
                    amount0Max: type(uint128).max,
                    amount1Max: type(uint128).max
                })
            );
            emit FeesCollected(id, amt0, amt1);

            (, , address t0, address t1, , , , , , , , ) = INonfungiblePositionManager(POSITION_MANAGER).positions(id);
            if (t0 == WLD) totalWLD += amt0;
            else if (amt0 > 0) totalWLD += swap(t0, WLD, amt0, deadline);
            if (t1 == WLD) totalWLD += amt1;
            else if (amt1 > 0) totalWLD += swap(t1, WLD, amt1, deadline);
        }

        uint256 reserveAmt = (totalWLD * RESERVE_FEE) / 100;
        reserveFund[WLD] += reserveAmt;

        uint256 remaining = totalWLD - reserveAmt;
        uint256 h2oAmt = (remaining * H2O_PCT) / 100;
        uint256 btch2oAmt = (remaining * BTCH2O_PCT) / 100;
        uint256 reinvestAmt = remaining - h2oAmt - btch2oAmt;

        swap(WLD, H2O, h2oAmt, deadline);
        swap(WLD, BTCH2O, btch2oAmt, deadline);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 id = tokenIds[i];
            if (inRange[id]) {
                INonfungiblePositionManager(POSITION_MANAGER).increaseLiquidity(
                    INonfungiblePositionManager.IncreaseLiquidityParams({
                        tokenId: id,
                        amount0Desired: reinvestAmt / tokenIds.length,
                        amount1Desired: reinvestAmt / tokenIds.length,
                        amount0Min: 0,
                        amount1Min: 0,
                        deadline: deadline
                    })
                );
                emit Reinvested(id, reinvestAmt / tokenIds.length);
            }
        }
    }

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

    function withdrawReserve(address token, uint256 amount) external onlyOwner {
        require(reserveFund[token] >= amount, "Insufficient funds");
        reserveFund[token] -= amount;
        IERC20(token).safeTransfer(owner(), amount);
    }
}
