// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface IUniswapV3Factory {
    function getPool(address tokenA, address tokenB, uint24 fee) external view returns (address);
}

interface IUniswapV3Pool {
    function slot0() external view returns (
        uint160 sqrtPriceX96,
        int24 tick,
        uint16,uint16,uint16,uint16,bool
    );
    function token0() external view returns (address);
    function token1() external view returns (address);
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
    function increaseLiquidity(IncreaseLiquidityParams calldata params)
        external returns (uint128 liquidity, uint256 amount0, uint256 amount1);
    function ownerOf(uint256 tokenId) external view returns (address);
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

contract AutoReinvestBotV5 is ReentrancyGuard {
    using SafeERC20 for IERC20;

    // ── World Chain Uniswap V3 addresses ──────────────────────────────────
    address public constant POSITION_MANAGER = 0xec12a9F9a09f50550686363766Cc153D03c27b5e;
    address public constant SWAP_ROUTER      = 0x091AD9e2e6e5eD44c1c66dB50e49A601F9f36cF6;
    address public constant UNISWAP_FACTORY  = 0x7a5028BDa40e7B173C278C5342087826455ea25a;

    // ── Tokens ────────────────────────────────────────────────────────────
    address public immutable WLD;
    address public immutable H2O;
    address public immutable BTCH2O;

    // ── Owners ────────────────────────────────────────────────────────────
    address public primaryOwner;
    mapping(address => bool) public isOwner;
    address[] public ownerList;

    // ── Config ────────────────────────────────────────────────────────────
    uint256 public slippageBps;          // basis points slippage tolerance (0 = no limit)
    uint256 public reinvestIntervalSecs; // target interval in seconds for the bot
    uint256 public reserveFeeBps;        // % kept as reserve (basis points)
    uint256 public h2oShareBps;          // % of remaining swapped to H2O
    uint256 public btch2oShareBps;       // % of remaining swapped to BTCH2O
    bool    public paused;
    uint256 public lastReinvestAt;

    // ── Positions ─────────────────────────────────────────────────────────
    mapping(uint256 => bool) public isManaged;
    mapping(uint256 => bool) public inRange;
    uint256[] public managedPositions;

    // ── Reserves ─────────────────────────────────────────────────────────
    mapping(address => uint256) public reserve;

    // ── Events ───────────────────────────────────────────────────────────
    event OwnerAdded(address indexed owner);
    event OwnerRemoved(address indexed owner);
    event PositionAdded(uint256 indexed tokenId);
    event PositionRemoved(uint256 indexed tokenId);
    event FeesCollected(uint256 indexed tokenId, uint256 amount0, uint256 amount1);
    event Swapped(address indexed tokenIn, address indexed tokenOut, uint256 amountIn, uint256 amountOut);
    event LiquidityAdded(uint256 indexed tokenId, uint128 liquidity);
    event ReserveWithdrawn(address indexed token, address indexed to, uint256 amount);
    event ConfigUpdated(string key, uint256 value);
    event Paused(bool isPaused);
    event ReinvestCompleted(uint256 timestamp, uint256 totalWLD);

    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not an owner");
        _;
    }

    modifier notPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    constructor(
        address _WLD,
        address _H2O,
        address _BTCH2O
    ) {
        WLD    = _WLD;
        H2O    = _H2O;
        BTCH2O = _BTCH2O;

        primaryOwner = msg.sender;
        isOwner[msg.sender] = true;
        ownerList.push(msg.sender);

        // Defaults
        slippageBps          = 0;     // no slippage limit
        reinvestIntervalSecs = 300;   // 5 minutes
        reserveFeeBps        = 200;   // 2%
        h2oShareBps          = 4000;  // 40%
        btch2oShareBps       = 3000;  // 30%
                                      // 30% goes to reinvest
    }

    // ─────────────────────────────────────────────────────────────────────
    //  Owner management
    // ─────────────────────────────────────────────────────────────────────

    function addOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Zero address");
        require(!isOwner[newOwner], "Already owner");
        isOwner[newOwner] = true;
        ownerList.push(newOwner);
        emit OwnerAdded(newOwner);
    }

    function removeOwner(address owner) external {
        require(msg.sender == primaryOwner, "Only primary owner");
        require(owner != primaryOwner, "Cannot remove primary owner");
        require(isOwner[owner], "Not an owner");
        isOwner[owner] = false;
        for (uint256 i = 0; i < ownerList.length; i++) {
            if (ownerList[i] == owner) {
                ownerList[i] = ownerList[ownerList.length - 1];
                ownerList.pop();
                break;
            }
        }
        emit OwnerRemoved(owner);
    }

    function getOwners() external view returns (address[] memory) {
        return ownerList;
    }

    // ─────────────────────────────────────────────────────────────────────
    //  Configuration
    // ─────────────────────────────────────────────────────────────────────

    function setSlippage(uint256 bps) external onlyOwner {
        require(bps <= 10000, "Max 100%");
        slippageBps = bps;
        emit ConfigUpdated("slippageBps", bps);
    }

    function setReinvestInterval(uint256 secs) external onlyOwner {
        require(secs >= 60, "Min 60s");
        reinvestIntervalSecs = secs;
        emit ConfigUpdated("reinvestIntervalSecs", secs);
    }

    function setReserveFeeBps(uint256 bps) external onlyOwner {
        require(bps <= 2000, "Max 20%");
        reserveFeeBps = bps;
        emit ConfigUpdated("reserveFeeBps", bps);
    }

    function setDistribution(uint256 _h2oShareBps, uint256 _btch2oShareBps) external onlyOwner {
        require(_h2oShareBps + _btch2oShareBps <= 10000, "Shares exceed 100%");
        h2oShareBps    = _h2oShareBps;
        btch2oShareBps = _btch2oShareBps;
        emit ConfigUpdated("h2oShareBps",    _h2oShareBps);
        emit ConfigUpdated("btch2oShareBps", _btch2oShareBps);
    }

    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
        emit Paused(_paused);
    }

    // ─────────────────────────────────────────────────────────────────────
    //  Position management
    // ─────────────────────────────────────────────────────────────────────

    function addPosition(uint256 tokenId) external onlyOwner {
        require(!isManaged[tokenId], "Already managed");
        managedPositions.push(tokenId);
        isManaged[tokenId] = true;
        _updateRange(tokenId);
        emit PositionAdded(tokenId);
    }

    function removePosition(uint256 tokenId) external onlyOwner {
        require(isManaged[tokenId], "Not managed");
        isManaged[tokenId] = false;
        for (uint256 i = 0; i < managedPositions.length; i++) {
            if (managedPositions[i] == tokenId) {
                managedPositions[i] = managedPositions[managedPositions.length - 1];
                managedPositions.pop();
                break;
            }
        }
        emit PositionRemoved(tokenId);
    }

    function getManagedPositions() external view returns (uint256[] memory) {
        return managedPositions;
    }

    function updateRanges(uint256[] calldata tokenIds) external onlyOwner {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (isManaged[tokenIds[i]]) {
                _updateRange(tokenIds[i]);
            }
        }
    }

    function _updateRange(uint256 tokenId) internal {
        (
            ,
            ,
            address t0,
            address t1,
            uint24 fee,
            int24 tLower,
            int24 tUpper,
            ,,,,
        ) = INonfungiblePositionManager(POSITION_MANAGER).positions(tokenId);

        address pool = IUniswapV3Factory(UNISWAP_FACTORY).getPool(t0, t1, fee);
        if (pool != address(0)) {
            (, int24 tick,,,,,) = IUniswapV3Pool(pool).slot0();
            inRange[tokenId] = (tick >= tLower && tick <= tUpper);
        }
    }

    // ─────────────────────────────────────────────────────────────────────
    //  Core reinvest logic
    // ─────────────────────────────────────────────────────────────────────

    function collectFees(
        uint256[] calldata tokenIds,
        uint256 deadline
    ) external onlyOwner notPaused nonReentrant {
        uint256 totalWLD;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 id = tokenIds[i];
            require(isManaged[id], "Not managed");

            (,, address token0,,,,,,,,,) =
                INonfungiblePositionManager(POSITION_MANAGER).positions(id);

            (uint256 a0, uint256 a1) = INonfungiblePositionManager(POSITION_MANAGER).collect(
                INonfungiblePositionManager.CollectParams({
                    tokenId: id,
                    recipient: address(this),
                    amount0Max: type(uint128).max,
                    amount1Max: type(uint128).max
                })
            );

            emit FeesCollected(id, a0, a1);
            totalWLD += (token0 == WLD ? a0 : a1);
        }

        if (totalWLD == 0) return;

        uint256 reserveAmt = (totalWLD * reserveFeeBps) / 10000;
        reserve[WLD]      += reserveAmt;
        uint256 remaining  = totalWLD - reserveAmt;

        uint256 h2oAmt    = (remaining * h2oShareBps)    / 10000;
        uint256 btch2oAmt = (remaining * btch2oShareBps) / 10000;
        uint256 reinvest  = remaining - h2oAmt - btch2oAmt;

        if (h2oAmt    > 0) _swap(WLD, H2O,    h2oAmt,    deadline);
        if (btch2oAmt > 0) _swap(WLD, BTCH2O, btch2oAmt, deadline);

        if (reinvest > 0 && tokenIds.length > 0) {
            uint256 perPosition = reinvest / tokenIds.length;
            for (uint256 i = 0; i < tokenIds.length; i++) {
                if (inRange[tokenIds[i]] && perPosition > 0) {
                    _addLiquidity(tokenIds[i], perPosition, deadline);
                }
            }
        }

        lastReinvestAt = block.timestamp;
        emit ReinvestCompleted(block.timestamp, totalWLD);
    }

    function _swap(
        address tokenIn,
        address tokenOut,
        uint256 amtIn,
        uint256 deadline
    ) internal returns (uint256 amtOut) {
        IERC20(tokenIn).forceApprove(SWAP_ROUTER, amtIn);

        uint256 minOut = slippageBps == 0
            ? 0
            : _getMinOut(tokenIn, tokenOut, amtIn);

        amtOut = ISwapRouter(SWAP_ROUTER).exactInputSingle(
            ISwapRouter.ExactInputSingleParams({
                tokenIn:           tokenIn,
                tokenOut:          tokenOut,
                fee:               3000,
                recipient:         address(this),
                deadline:          deadline,
                amountIn:          amtIn,
                amountOutMinimum:  minOut,
                sqrtPriceLimitX96: 0
            })
        );

        IERC20(tokenIn).forceApprove(SWAP_ROUTER, 0);
        emit Swapped(tokenIn, tokenOut, amtIn, amtOut);
    }

    function _getMinOut(
        address, /*tokenIn*/
        address, /*tokenOut*/
        uint256 amtIn
    ) internal view returns (uint256) {
        // Simple slippage: (amtIn * (10000 - slippageBps)) / 10000
        // In production this should use a price oracle
        return (amtIn * (10000 - slippageBps)) / 10000;
    }

    function _addLiquidity(
        uint256 tokenId,
        uint256 amtWLD,
        uint256 deadline
    ) internal {
        (,, address token0,,,,,,,,,) =
            INonfungiblePositionManager(POSITION_MANAGER).positions(tokenId);

        (address t0Addr, address t1Addr) = token0 == WLD
            ? (WLD, H2O)
            : (H2O, WLD);

        IERC20(t0Addr).forceApprove(POSITION_MANAGER, amtWLD);
        IERC20(t1Addr).forceApprove(POSITION_MANAGER, amtWLD);

        (uint128 liq,,) = INonfungiblePositionManager(POSITION_MANAGER).increaseLiquidity(
            INonfungiblePositionManager.IncreaseLiquidityParams({
                tokenId:        tokenId,
                amount0Desired: amtWLD,
                amount1Desired: amtWLD,
                amount0Min:     0,
                amount1Min:     0,
                deadline:       deadline
            })
        );

        IERC20(t0Addr).forceApprove(POSITION_MANAGER, 0);
        IERC20(t1Addr).forceApprove(POSITION_MANAGER, 0);

        emit LiquidityAdded(tokenId, liq);
    }

    // ─────────────────────────────────────────────────────────────────────
    //  Reserve management
    // ─────────────────────────────────────────────────────────────────────

    function withdrawReserve(address token, uint256 amount, address to) external onlyOwner {
        require(reserve[token] >= amount, "Insufficient reserve");
        reserve[token] -= amount;
        IERC20(token).safeTransfer(to, amount);
        emit ReserveWithdrawn(token, to, amount);
    }

    function withdrawAll(address token, address to) external onlyOwner {
        uint256 bal = IERC20(token).balanceOf(address(this));
        require(bal > 0, "Nothing to withdraw");
        IERC20(token).safeTransfer(to, bal);
        emit ReserveWithdrawn(token, to, bal);
    }

    // ─────────────────────────────────────────────────────────────────────
    //  View helpers
    // ─────────────────────────────────────────────────────────────────────

    function getConfig() external view returns (
        uint256 _slippageBps,
        uint256 _reinvestIntervalSecs,
        uint256 _reserveFeeBps,
        uint256 _h2oShareBps,
        uint256 _btch2oShareBps,
        bool    _paused,
        uint256 _lastReinvestAt
    ) {
        return (
            slippageBps,
            reinvestIntervalSecs,
            reserveFeeBps,
            h2oShareBps,
            btch2oShareBps,
            paused,
            lastReinvestAt
        );
    }

    function getPosition(uint256 tokenId) external view returns (
        address token0,
        address token1,
        uint24 fee,
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity,
        uint128 tokensOwed0,
        uint128 tokensOwed1,
        bool managed,
        bool isInRange
    ) {
        (
            ,
            ,
            token0,
            token1,
            fee,
            tickLower,
            tickUpper,
            liquidity,
            ,
            ,
            tokensOwed0,
            tokensOwed1
        ) = INonfungiblePositionManager(POSITION_MANAGER).positions(tokenId);
        managed   = isManaged[tokenId];
        isInRange = inRange[tokenId];
    }

    function getReserves() external view returns (
        uint256 wldReserve,
        uint256 h2oReserve,
        uint256 btch2oReserve
    ) {
        return (reserve[WLD], reserve[H2O], reserve[BTCH2O]);
    }
}
