# PROYECTO DOLA — AutoReinvest Bot V5 (World Chain)

## Overview
Full-stack DeFi automation: a Solidity smart contract + React frontend + Node.js bot for
automatically collecting Uniswap V3 fees on World Chain and reinvesting them into WLD/H2O/BTCH2O.

## Deployed Contract
- **AutoReinvestBotV5**: `0x618B521C3d7DAD1a2F186aD830E69ba6d5081E1E`
- **Worldscan**: https://worldscan.org/address/0x618B521C3d7DAD1a2F186aD830E69ba6d5081E1E
- **Network**: World Chain (Chain ID: 480)

## Project Structure
```
contracts/
  AutoReinvestBotV5.sol     Main smart contract
scripts/
  deploy.js                 Deploy to World Chain
  verify.js                 Verify on Worldscan
  processFees.js            Bot: collect fees & reinvest every N seconds
  addPosition.js            Add NFT position to bot
  removePosition.js         Remove NFT position
  addOwner.js               Add owner wallet
  getPositions.js           List all positions
  getReserves.js            View token reserves
  withdrawReserves.js       Withdraw from reserves
  updateConfig.js           Update contract config
src/                        React frontend (Vite)
  config/
    wagmi.js                WalletConnect + wagmi setup
    contract.js             ABI + contract address
  pages/
    Dashboard.jsx           User dashboard
    OwnerPanel.jsx          Owner admin panel
  components/               UI components
  hooks/                    React hooks for contract interaction
  styles/                   CSS styles
AutoReinvestBotV5_flat.sol  Flattened contract for manual verification
hardhat.config.js           Hardhat + network configuration
vite.config.js              Vite frontend configuration
```

## Secrets Required
| Secret | Description |
|--------|-------------|
| `PRIVATE_KEY` | Wallet private key for deploy/bot |
| `WLD_TOKEN` | WLD token address on World Chain |
| `H2O_TOKEN` | H2O token address on World Chain |
| `BTCH2O_TOKEN` | BTCH2O token address on World Chain |
| `STAKING_CONTRACT` | Deployed bot contract address (update to `0x618B521C3d7DAD1a2F186aD830E69ba6d5081E1E`) |
| `WORLD_APY_KEY` | Worldscan API key for contract verification |
| `WORLD_CHAIN_URL` | (Optional) Custom RPC URL |

## Available Commands
```bash
npm run dev          # Start React frontend (port 5000)
npm run compile      # Compile contracts
npm run deploy       # Deploy AutoReinvestBotV5 to World Chain
npm run verify       # Verify contract on Worldscan
npm run process-fees # Start reinvest bot (runs indefinitely)
npm run test         # Run Hardhat tests
```

## Contract Features (V5)
- **Multi-owner**: Primary owner can add/remove other owners
- **Configurable slippage**: 0 = no limit (default), or set in basis points
- **Configurable interval**: Default 5 minutes (300s)
- **Fee distribution**: 2% reserve, 40% → H2O, 30% → BTCH2O, 30% → reinvest
- **Emergency pause**: Owner can pause all operations
- **Reserve management**: Withdraw accumulated tokens

## Frontend Features
- WalletConnect integration (project ID: befde1d683c68f9cf789993998fbda38)
- Dashboard: position cards, bot on/off toggle, stats
- Owner Panel: config, positions, reserves, owners management, contract info
- Import pools/NFTs/LP positions by token ID

## Uniswap V3 Addresses (World Chain)
- Position Manager: `0xec12a9F9a09f50550686363766Cc153D03c27b5e`
- Swap Router: `0x091AD9e2e6e5eD44c1c66dB50e49A601F9f36cF6`
- Factory: `0x7a5028BDa40e7B173C278C5342087826455ea25a`

## Key Dependencies
- Solidity 0.8.20 + OpenZeppelin v5 + Uniswap V3
- React 18 + Vite 5 + wagmi v2 + viem v2
- WalletConnect Web3Modal v4
- Hardhat ^2.22.3

## Important Notes
- Update `STAKING_CONTRACT` secret to `0x618B521C3d7DAD1a2F186aD830E69ba6d5081E1E`
- For manual verification: use `AutoReinvestBotV5_flat.sol` on https://worldscan.org
