# Acua Company — AutoReinvest Bot V6 (World Chain)

## Overview
Full-stack DeFi automation: a Solidity smart contract + React frontend for automatically
collecting Uniswap V3 fees on World Chain and reinvesting them. Multi-token support for
any ERC20 pair, configurable slippage and fee tiers, multi-token reserve panel, and triple
staking (ACUA, TIME direct, SUSHI memberships).

## Deployed Contracts
- **AutoReinvestBotV6**: `0xaAF4965b640730dECe37638BE429a48Fe4E0BCCE`
- **ACUA Staking**: `0x6d6D559bF261415a52c59Cb1617387B6534E5041`
- **TIME Staking**: `0x17e32C9E063533529F802839B9bA93e70D8953FE`
- **SUSHI Staking**: `0x500EC550891D8f03DdD32d5854A3B15d052299Ca`
- **Network**: World Chain (Chain ID: 480)
- **Worldscan**: https://worldscan.org/address/0xaAF4965b640730dECe37638BE429a48Fe4E0BCCE

## Key Token Addresses
- WLD: `0x2cFc85d8E48F8EAB294be644d9E25C3030863003`
- TIME: `0x212d7448720852D8Ad282a5d4A895B3461F9076E`
- SUSHI: `0xab09A728E53d3d6BC438BE95eeD46Da0Bbe7FB38`

## Project Structure
```
contracts/
  AutoReinvestBotV6.sol     Main smart contract (multi-token, configurable)
scripts/
  deployV6.js               Deploy V6 to World Chain
src/                        React frontend (Vite)
  config/
    wagmi.js                WalletConnect + wagmi setup
    contract.js             AutoReinvest V6 ABI + address
    staking.js              ACUA Staking ABI + ERC20 ABI
    sushi.js                SUSHI token + staking ABIs
    time.js                 TIME token + TIME staking ABIs + WLD address
  pages/
    Dashboard.jsx           User dashboard with bot control
    OwnerPanel.jsx          Owner admin panel
    StakingPage.jsx         Staking hub page
  components/
    BotControl.jsx          Bot start/stop + manual reinvest/claim + last 10 logs
    PositionCard.jsx        Uniswap V3 position card with fees display
    StakingPanel.jsx        Triple staking: ACUA + TIME (direct) + SUSHI (memberships)
    ConfigPanel.jsx         V6 config: interval, reserveFee, slippage, defaultFeeTier
    ReservePanel.jsx        Multi-token reserve panel (dynamic token list)
    Header.jsx              Navigation header
  hooks/
    useBot.js               Bot logic — uses collectAllManaged() for V6
    useContract.js          wagmi hooks for AutoReinvest contract
  styles/                   CSS styles
hardhat.config.js           Hardhat + network configuration
vite.config.js              Vite frontend configuration
```

## Frontend Pages
- **/** Dashboard: Position cards, Bot control panel, manual reinvest/claim buttons
- **/staking**: Staking Hub with three tabs (ACUA, TIME direct, SUSHI memberships)
- **/owner**: Owner admin panel (config, positions, reserves, owners)

## V6 Contract Features (AutoReinvestBotV6.sol)
- **Multi-token pairs**: Any ERC20 pair via addPosition(), not just WLD/H2O
- **Configurable distribution tokens**: addDistToken(token, shareBps, feeTier)
  - Replaces hardcoded H2O/BTCH2O from V5
  - Each dist token gets a share of collected WLD fees
- **Per-pair fee tier overrides**: setPairFeeTier(tokenA, tokenB, feeTier)
- **Configurable slippage**: setSlippageBps(bps) — V6 uses min-out protection
- **Default fee tier**: setDefaultSwapFeeTier(feeTier)
- **Reserve token management**: addReserveToken/removeReserveToken (any ERC20)
- **getReserveBalances()**: Returns (address[], uint256[]) for all reserve tokens
- **collectAllManaged(deadline)**: Collects all managed positions in one call
- **Inline FullMath mulDiv**: No external library dependency

## V6 getConfig() Return Values
`[reinvestIntervalSecs, reserveFeeBps, slippageBps, defaultSwapFeeTier, paused, lastReinvestAt]`
Note: V5 had [interval, reserveFee, h2oShare, btch2oShare, paused, lastReinvest]

## V6 Constructor Parameters
`(WLD_address, TIME_TOKEN_address, TIME_STAKING_address)`

## Staking Panels
- **ACUA**: Via ACUA_STAKING_ADDRESS, stake/unstake ACUA, claim ACUA rewards
- **TIME (DIRECT)**: Via TIME_STAKING_ADDRESS directly (NOT through the bot), stake/unstake TIME, claim WLD rewards via `claimWldReward()`
- **SUSHI**: Via SUSHI_STAKING_ADDRESS, buy membership (4 tiers: Plata/Oro/Platino/Diamante), retirarIntereses(), retirarBalance()

## Bot Behavior (useBot.js)
- `collectAllManaged(deadline)` — V6 main call (no tokenIds needed)
- `claimStakingRewards(deadline)` — claim TIME staking WLD rewards through bot
- Auto-reads position fees and in-range status via `getPosition()`
- Interval-based reinvestment loop with manual override buttons

## Available Commands
```bash
npm run dev          # Start React frontend (port 5000)
echo "n" | npx hardhat compile   # Compile contracts
echo "n" | npx hardhat run scripts/deployV6.js --network worldchain   # Deploy V6
```

## Key Dependencies
- React 18 + Vite 5 + wagmi v2 + viem v2
- WalletConnect Web3Modal v4 (project ID: befde1d683c68f9cf789993998fbda38)
- Solidity 0.8.20 + OpenZeppelin v5 + Uniswap V3

## Uniswap V3 Addresses (World Chain)
- Position Manager: `0xec12a9F9a09f50550686363766Cc153D03c27b5e`
- Swap Router: `0x091AD9e2e6e5eD44c1c66dB50e49A601F9f36cF6`
- Factory: `0x7a5028BDa40e7B173C278C5342087826455ea25a`

## Vite Config Note
`@reown/appkit` is excluded from optimizeDeps to avoid source map parse errors.
