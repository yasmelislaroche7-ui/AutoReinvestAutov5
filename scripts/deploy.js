const { ethers } = require("hardhat");
require("dotenv").config();

async function main() {
  const WLD_TOKEN    = process.env.WLD_TOKEN;
  const H2O_TOKEN    = process.env.H2O_TOKEN;
  const BTCH2O_TOKEN = process.env.BTCH2O_TOKEN;

  if (!WLD_TOKEN || !H2O_TOKEN || !BTCH2O_TOKEN) {
    throw new Error("Missing token env vars: WLD_TOKEN, H2O_TOKEN, BTCH2O_TOKEN");
  }

  const [deployer] = await ethers.getSigners();
  console.log(`Deployer: ${deployer.address}`);
  const balance = await ethers.provider.getBalance(deployer.address);
  console.log(`Balance: ${ethers.formatEther(balance)} ETH`);

  console.log("\nDeployando AutoReinvestBotV5...");
  const Factory = await ethers.getContractFactory("AutoReinvestBotV5");
  const bot = await Factory.deploy(WLD_TOKEN, H2O_TOKEN, BTCH2O_TOKEN);
  await bot.waitForDeployment();

  const address = await bot.getAddress();
  console.log(`\n✅ Contrato deployado en: ${address}`);
  console.log(`🔗 Worldscan: https://worldscan.io/address/${address}`);
  console.log(`\nGuarda esta dirección como STAKING_CONTRACT en los secrets de Replit.`);

  // Save address to file for verify script
  const fs = require("fs");
  fs.writeFileSync(".deployed_address", address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
