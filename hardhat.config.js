require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

const PRIVATE_KEY = process.env.PRIVATE_KEY;

module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.20",
        settings: {
          optimizer: { enabled: true, runs: 200 },
          viaIR: true
        }
      },
      {
        version: "0.8.24",
        settings: {
          optimizer: { enabled: true, runs: 200 },
          viaIR: true
        }
      }
    ]
  },
  networks: {
    worldchain: {
      url: process.env.WORLD_CHAIN_URL || "https://worldchain-mainnet.g.alchemy.com/public",
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
      chainId: 480,
      timeout: 120000
    },
    localhost: {
      url: "http://127.0.0.1:8545",
      chainId: 31337
    }
  },
  etherscan: {
    apiKey: {
      worldchain: process.env.ETHER_KEY || process.env.WORLD_APY_KEY || "placeholder"
    },
    customChains: [
      {
        network: "worldchain",
        chainId: 480,
        urls: {
          apiURL: "https://api.worldscan.org/api",
          browserURL: "https://worldscan.org"
        }
      }
    ]
  },
  sourcify: {
    enabled: false
  }
};
