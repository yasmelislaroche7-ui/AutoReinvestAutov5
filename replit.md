# PROYECTO DOLA — Auto Reinvest Bot (World Chain)

## Overview
This is a Hardhat smart contract development project for an automated reinvestment bot on Uniswap V3 running on the World Chain network. The bot collects liquidity position fees, swaps portions into H2O and BTCH2O tokens, and reinvests the remainder back into the pool.

## Project Structure
- `contracts/AutoReinvestBotV4.sol` — Main smart contract
- `scripts/deploy.js` — Deployment script
- `scripts/verify.js` — Contract verification on Worldscan
- `hardhat.config.js` — Hardhat configuration (networks, compiler, Etherscan)

## Available Commands
- `npm run compile` — Compile contracts
- `npm run deploy` — Deploy to World Chain (requires `PRIVATE_KEY` secret)
- `npm run process-fees` — Run the fee collection and reinvestment bot
- `npm run verify` — Verify contract on Worldscan (requires `WORLD_SCAN_API_KEY` secret)
- `npm run test` — Run tests
- `npm run node` — Start a local Hardhat node

## Environment Variables / Secrets Required
- `PRIVATE_KEY` — Wallet private key for deploying and interacting with contracts
- `WORLD_CHAIN_URL` — (Optional) Custom World Chain RPC URL; defaults to `https://rpc.worldchain.gg`
- `WORLD_SCAN_API_KEY` — (Optional) Worldscan API key for contract verification

## Network
- **World Chain** — Chain ID 480
- **RPC**: `https://rpc.worldchain.gg` (default)
- **Explorer**: https://worldscan.io

## Compiler Settings
- Solidity 0.8.20 with optimizer (200 runs) and `viaIR: true`
- Solidity 0.8.24 with optimizer (200 runs) and `viaIR: true`

## Key Dependencies
- `hardhat` ^2.22.3
- `@openzeppelin/contracts` ^5.0.1
- `@uniswap/v3-core` ^1.0.1
- `@uniswap/v3-periphery` ^1.4.4
