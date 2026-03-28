const { ethers } = require("hardhat");

async function main() {
  // OBTENER CONTRATO
  const AutoReinvestBotV4 = await ethers.getContractFactory("AutoReinvestBotV4");

  // DATOS QUE DEBES CONFIGURAR
  const STAKING_CONTRACT = "0x17e32c9e063533529f802839b9ba93e70d8953fe";
  const WLD_TOKEN = "0x2cfc85d8e48f8eab294be644d9e25c3030863003";
  const H2O_TOKEN = "0x17392e5483983945dEB92e0518a8F2C4eB6bA59d";
  const BTCH2O_TOKEN = "0xEcC4dAe4DC3D359a93046bd944e9ee3421A6A484";

  // DEPLOY
  console.log("Deployando contrato...");
  const bot = await AutoReinvestBotV4.deploy(
    STAKING_CONTRACT,
    WLD_TOKEN,
    H2O_TOKEN,
    BTCH2O_TOKEN
  );
  await bot.deployed();

  console.log(`Contrato deployado en: ${bot.address}`);
  console.log(`Verifica aquí: https://worldscan.io/address/${bot.address}`);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
