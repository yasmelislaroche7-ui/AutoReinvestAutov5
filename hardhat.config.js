require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

module.exports = {
  solidity: {
    compilers: [
      { version: "0.8.20" }, // Para tu contrato
      { version: "0.8.24" }  // Para OpenZeppelin v5
    ]
  },
  networks: {
    worldchain: {
      url: process.env.WORLD_CHAIN_URL || "https://rpc.worldchain.gg",
      accounts: [process.env.PRIVATE_KEY],
      chainId: 480
    },
    localhost: {
      url: "http://127.0.0.1:8545",
      chainId: 31337
    }
  },
  etherscan: {
    apiKey: {
      worldchain: process.env.WORLD_SCAN_API_KEY
    },
    customChains: [
      {
        network: "worldchain",
        chainId: 480,
        urls: {
          apiURL: "https://api.worldscan.io/api",
          browserURL: "https://worldscan.io"
        }
      }
    ]
  }
};
