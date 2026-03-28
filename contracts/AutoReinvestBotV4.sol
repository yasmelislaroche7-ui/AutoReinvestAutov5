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
        uint96,address,address,address,uint24,
        int24,int24,uint128,
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

contract AutoReinvestBotV5 is Ownable2Step {
    using SafeERC20 for IERC20;

    address public constant POSITION_MANAGER = 0xEC12A9F9A09f50550686363766cC153D03C27B5E;
    address public constant SWAP_ROUTER = 0x091AD9e2e6e5Ed44c1c66dB50e49A601F9f36Cf6;
    address public constant UNISWAP_FACTORY = 0x7a5028BDa40e7B173C278C5342087826455ea25a;

    address public immutable WLD;
    address public immutable H2O;
    address public immutable BTCH2O;

    constructor(address _WLD,address _H2O,address _BTCH2O){
        WLD=_WLD; H2O=_H2O; BTCH2O=_BTCH2O;
    }

    mapping(uint256=>bool) public isManaged;
    mapping(uint256=>bool) public inRange;
    mapping(address=>uint256) public reserve;

    mapping(uint256=>address) public token0Of;
    mapping(uint256=>address) public token1Of;
    mapping(uint256=>uint24) public feeOf;
    mapping(uint256=>int24) public tickLowerOf;
    mapping(uint256=>int24) public tickUpperOf;

    uint256[] public managedPositions;

    event FeesCollected(uint256 id,uint256 a0,uint256 a1);

    // ================= ADD POSITION =================

    function addPosition(uint256 tokenId) external onlyOwner {
        require(!isManaged[tokenId],"Already managed");

        (
            ,,
            address t0,
            address t1,
            uint24 fee,
            int24 tLower,
            int24 tUpper,
            ,,,,
        ) = INonfungiblePositionManager(POSITION_MANAGER).positions(tokenId);

        token0Of[tokenId]=t0;
        token1Of[tokenId]=t1;
        feeOf[tokenId]=fee;
        tickLowerOf[tokenId]=tLower;
        tickUpperOf[tokenId]=tUpper;

        managedPositions.push(tokenId);
        isManaged[tokenId]=true;
        _updateRange(tokenId);
    }

    // ================= RANGE CHECK =================

    function _updateRange(uint256 tokenId) internal returns(bool){
        address pool=IUniswapV3Factory(UNISWAP_FACTORY).getPool(
            token0Of[tokenId],token1Of[tokenId],feeOf[tokenId]
        );
        (,int24 currentTick,,,,,)=IUniswapV3Pool(pool).slot0();

        bool status=currentTick>=tickLowerOf[tokenId] && currentTick<=tickUpperOf[tokenId];
        inRange[tokenId]=status;
        return status;
    }

    // ================= MAIN EXECUTION =================

    function collectFees(uint256[] calldata tokenIds,uint256 deadline) external onlyOwner {
        uint256 totalWLD;

        for(uint i=0;i<tokenIds.length;i++){
            uint256 id=tokenIds[i];
            require(isManaged[id],"Not managed");

            (uint256 a0,uint256 a1)=INonfungiblePositionManager(POSITION_MANAGER).collect(
                INonfungiblePositionManager.CollectParams({
                    tokenId:id,
                    recipient:address(this),
                    amount0Max:type(uint128).max,
                    amount1Max:type(uint128).max
                })
            );

            emit FeesCollected(id,a0,a1);

            address t0=token0Of[id];
            totalWLD += (t0==WLD ? a0 : a1);
        }

        if(totalWLD==0) return;

        // ===== DISTRIBUCION =====
        uint256 reserveFee=(totalWLD*2)/100;
        reserve[WLD]+=reserveFee;

        uint256 remaining=totalWLD-reserveFee;

        _swap(WLD,H2O,(remaining*40)/100,deadline);
        _swap(WLD,BTCH2O,(remaining*30)/100,deadline);

        uint256 reinvest=(remaining*30)/100;
        uint256 perPosition=reinvest/tokenIds.length;

        for(uint i=0;i<tokenIds.length;i++){
            if(!_updateRange(tokenIds[i])) continue;

            INonfungiblePositionManager(POSITION_MANAGER).increaseLiquidity(
                INonfungiblePositionManager.IncreaseLiquidityParams({
                    tokenId:tokenIds[i],
                    amount0Desired:perPosition,
                    amount1Desired:perPosition,
                    amount0Min:0,
                    amount1Min:0,
                    deadline:deadline
                })
            );
        }
    }

    // ================= SWAP =================

    function _swap(address from,address to,uint256 amt,uint256 deadline) internal {
        if(amt==0) return;

        IERC20(from).safeApprove(SWAP_ROUTER,0);
        IERC20(from).safeApprove(SWAP_ROUTER,amt);

        ISwapRouter(SWAP_ROUTER).exactInputSingle(
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

    // ================= RESCUE =================

    function rescueToken(address token) external onlyOwner {
        uint256 bal=IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(owner(),bal);
    }
}