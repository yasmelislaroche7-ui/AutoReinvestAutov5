const { ethers } = require("hardhat");

async function main() {
  // OBTENER CONTRATO
  const AutoReinvestBotV4 = await ethers.getContractFactory("AutoReinvestBotV4");

  // DATOS QUE DEBES CONFIGURAR
  const STAKING_CONTRACT = "DIRECCION_CONTRATO_STAKING_AQUI";
  const WLD_TOKEN = "DIRECCION_TOKEN_WLD_AQUI";
  const H2O_TOKEN = "DIRECCION_TOKEN_H2O_AQUI";
  const BTCH2O_TOKEN = "DIRECCION_TOKEN_BTCH2O_AQUI";

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
