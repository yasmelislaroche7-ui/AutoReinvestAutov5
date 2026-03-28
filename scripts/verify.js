const { run } = require("hardhat");

async function main() {
  // DATOS DEL DEPLOY
  const CONTRACT_ADDRESS = "DIRECCION_DEL_CONTRATO_DEPLOYADO";
  const STAKING_CONTRACT = "DIRECCION_CONTRATO_STAKING";
  const WLD_TOKEN = "DIRECCION_TOKEN_WLD";
  const H2O_TOKEN = "DIRECCION_TOKEN_H2O";
  const BTCH2O_TOKEN = "DIRECCION_TOKEN_BTCH2O";

  // VERIFICACIÓN EN WORLDSCAN
  await run("verify:verify", {
    address: CONTRACT_ADDRESS,
    constructorArguments: [
      STAKING_CONTRACT,
      WLD_TOKEN,
      H2O_TOKEN,
      BTCH2O_TOKEN
    ]
  });

  console.log("Contrato verificado exitosamente!");
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
