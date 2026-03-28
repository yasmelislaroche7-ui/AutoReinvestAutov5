// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IUniswapV3Factory {
    function getPool(address tokenA, address tokenB, uint24 fee) external view returns (address);
}

interface IUniswapV3Pool {
    function slot0() external view returns (
        uint160 sqrtPriceX96,
        int24 tick,
        uint16,uint16,uint16,uint16,bool
    );
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
        uint96,address,address token0,address token1,uint24,
        int24 tickLower,int24 tickUpper,uint128,
        uint256,uint256,uint128,uint128
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

contract AutoReinvestBotV4 is Ownable2Step {
    using SafeERC20 for IERC20;

    // ✅ CHECKSUM ARREGLADO
    address public constant POSITION_MANAGER = 0xEC12A9F9A09f50550686363766cC153D03C27B5E;
    address public constant SWAP_ROUTER     = 0x091AD9e2e6e5Ed44c1c66dB50e49A601F9f36Cf6;
    address public constant UNISWAP_FACTORY = 0x7a5028BDa40E7B173C278C5342087826455Ea25A;

    address public immutable WLD;
    address public immutable H2O;
    address public immutable BTCH2O;

    // ✅ FIX OZ V5 CONSTRUCTOR
    constructor(address _WLD,address _H2O,address _BTCH2O) Ownable(msg.sender){
        WLD=_WLD; H2O=_H2O; BTCH2O=_BTCH2O;
    }

    mapping(uint256=>bool) public isManaged;
    mapping(uint256=>bool) public inRange;
    mapping(address=>uint256) public reserve;
    uint256[] public managedPositions;

    event FeesCollected(uint256 id,uint256 a0,uint256 a1);

    function addPosition(uint256 tokenId) external onlyOwner {
        require(!isManaged[tokenId],"Already managed");
        managedPositions.push(tokenId);
        isManaged[tokenId]=true;

        (, , address t0,address t1,uint24 fee,int24 tLower,int24 tUpper,,,,,) =
            INonfungiblePositionManager(POSITION_MANAGER).positions(tokenId);

        address pool=IUniswapV3Factory(UNISWAP_FACTORY).getPool(t0,t1,fee);
        (,int24 currentTick,,,,,)=IUniswapV3Pool(pool).slot0();
        inRange[tokenId]=(currentTick>=tLower&&currentTick<=tUpper);
    }

    function collectFees(uint256[] calldata tokenIds,uint256 deadline) external onlyOwner {
        uint256 totalWLD;

        for(uint256 i=0;i<tokenIds.length;i++){
            uint256 id=tokenIds[i];
            require(isManaged[id],"Not managed");

            // ✅ FIX: obtener tokens de la posición
            (, , address token0,address token1,,,,,,,) =
                INonfungiblePositionManager(POSITION_MANAGER).positions(id);

            (uint256 a0,uint256 a1)=INonfungiblePositionManager(POSITION_MANAGER).collect(
                INonfungiblePositionManager.CollectParams({
                    tokenId:id,
                    recipient:address(this),
                    amount0Max:type(uint128).max,
                    amount1Max:type(uint128).max
                })
            );

            emit FeesCollected(id,a0,a1);
            totalWLD += (token0==WLD ? a0 : a1);
        }

        uint256 reserveFee=(totalWLD*2)/100;
        reserve[WLD]+=reserveFee;
        uint256 remaining=totalWLD-reserveFee;

        swap(WLD,H2O,(remaining*40)/100,deadline);
        swap(WLD,BTCH2O,(remaining*30)/100,deadline);
        uint256 reinvest=(remaining*30)/100;

        for(uint256 i=0;i<tokenIds.length;i++){
            if(inRange[tokenIds[i]]){
                INonfungiblePositionManager(POSITION_MANAGER).increaseLiquidity(
                    INonfungiblePositionManager.IncreaseLiquidityParams({
                        tokenId:tokenIds[i],
                        amount0Desired:reinvest/tokenIds.length,
                        amount1Desired:reinvest/tokenIds.length,
                        amount0Min:0,
                        amount1Min:0,
                        deadline:deadline
                    })
                );
            }
        }
    }

    function swap(address from,address to,uint256 amt,uint256 deadline) internal returns(uint256){
        IERC20(from).safeApprove(SWAP_ROUTER,0);
        IERC20(from).safeApprove(SWAP_ROUTER,amt);

        return ISwapRouter(SWAP_ROUTER).exactInputSingle(
            ISwapRouter.ExactInputSingleParams({
                tokenIn:from,
                tokenOut:to,
                fee:3000,
                recipient:address(this),
                deadline:deadline,
                amountIn:amt,
                amountOutMinimum:0,
                sqrtPriceLimitX96:0
            })
        );
    }
}