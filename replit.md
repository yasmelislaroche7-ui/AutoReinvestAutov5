# Acua Company — AutoReinvest Bot V5 (World Chain)

## Overview
Full-stack DeFi automation: a Solidity smart contract + React frontend for automatically
collecting Uniswap V3 fees on World Chain and reinvesting them into WLD/H2O/BTCH2O.
Also supports dual staking: ACUA token staking and TIME token staking (via bot contract).

## Deployed Contracts
- **AutoReinvestBotV5**: `0x000051C9c9b556C8611cE1ceEDFc19140a1681d6`
- **ACUA Staking**: `0x6d6D559bF261415a52c59Cb1617387B6534E5041`
- **Network**: World Chain (Chain ID: 480)
- **Worldscan**: https://worldscan.org/address/0x000051C9c9b556C8611cE1ceEDFc19140a1681d6

## Project Structure
```
contracts/
  AutoReinvestBotV5.sol     Main smart contract
scripts/
  deploy.js                 Deploy to World Chain
  verify.js                 Verify on Worldscan
  processFees.js            Bot: collect fees & reinvest
src/                        React frontend (Vite)
  config/
    wagmi.js                WalletConnect + wagmi setup
    contract.js             AutoReinvest ABI + address
    staking.js              ACUA Staking ABI + ERC20 ABI
  pages/
    Dashboard.jsx           User dashboard with bot control
    OwnerPanel.jsx          Owner admin panel
    StakingPage.jsx         Staking hub page
  components/
    BotControl.jsx          Bot start/stop + manual reinvest/claim + last 10 logs
    PositionCard.jsx        Uniswap V3 position card with fees display
    StakingPanel.jsx        Dual staking (ACUA + TIME) with tab navigation
    Header.jsx              Navigation header
    ...
  hooks/
    useBot.js               Bot logic: real position reads, manual reinvest/claim
    useContract.js          wagmi hooks for AutoReinvest contract
    useStaking.js           Staking contract hooks + ERC20 approve
  styles/                   CSS styles
hardhat.config.js           Hardhat + network configuration
vite.config.js              Vite frontend configuration
```

## Frontend Pages
- **/** Dashboard: Position cards, Bot control panel, manual reinvest/claim buttons
- **/staking**: Staking Hub with two panels (ACUA stake, TIME stake)
- **/owner**: Owner admin panel (config, positions, reserves, owners)

## Frontend Features
- Rebranded to **Acua Company** (formerly PROYECTO DOLA)
- WalletConnect integration
- Dashboard: real-time position cards showing in-range status + pending fees
- Bot: starts/stops automated reinvest loop, shows last 10 log lines
- **Manual Reinvest** button: calls `collectAll()` on the bot contract
- **Manual Claim** button: calls `claimStakingRewards()` on the bot contract
- Total unclaimed fees summary (Token 0 / Token 1)
- In-range position counter
- **ACUA Staking Panel**: stake/unstake/claim from `0x6d6D559bF261415a52c59Cb1617387B6534E5041`
- **TIME Staking Panel**: stake/unstake TIME, claim WLD via AutoReinvest bot
- ERC20 approve flow before staking (auto-detected)

## AutoReinvest Bot Functions Used
- `collectAll()` — collect fees + reinvest
- `collectFees()` — collect fees only
- `claimStakingRewards()` — claim WLD from TIME staking
- `stakeTime(amount)` / `unstakeTime(amount)` — TIME staking via bot
- `getStakingInfo()` / `pendingStakingReward` / `stakedTimeBalance` — TIME staking reads
- `getPosition(tokenId)` — reads in-range status + pending fees
- `getManagedPositions()` — list of managed NFT IDs
- `getConfig()` — contract config (slippage, interval, pause state)
- `TIME_TOKEN` — TIME token address getter

## Available Commands
```bash
npm run dev          # Start React frontend (port 5000)
npm run compile      # Compile contracts
npm run deploy       # Deploy AutoReinvestBotV5 to World Chain
npm run verify       # Verify contract on Worldscan
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
