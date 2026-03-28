const { ethers } = require("hardhat");
require("dotenv").config();

const INTERVAL_MS = (parseInt(process.env.REINVEST_INTERVAL_SECS) || 300) * 1000;

async function reinvest(contract) {
  try {
    const positions = await contract.getManagedPositions();
    if (positions.length === 0) {
      console.log("[Bot] No hay posiciones gestionadas.");
      return;
    }

    const isPaused = await contract.paused();
    if (isPaused) {
      console.log("[Bot] Contrato pausado, saltando...");
      return;
    }

    const deadline = Math.floor(Date.now() / 1000) + 600;
    const ids = positions.map(p => p.toString());
    console.log(`[Bot] Reinvirtiendo ${ids.length} posicion(es): ${ids.join(", ")}`);

    await contract.updateRanges(positions);
    const tx = await contract.collectFees(positions, deadline);
    await tx.wait();
    console.log(`[Bot] ✅ Reinversión completada. TX: ${tx.hash}`);
  } catch (err) {
    console.error("[Bot] ❌ Error en reinversión:", err.message);
  }
}

async function main() {
  const address = process.env.STAKING_CONTRACT;
  if (!address) throw new Error("STAKING_CONTRACT no configurado.");

  const [signer] = await ethers.getSigners();
  console.log(`[Bot] Cuenta: ${signer.address}`);

  const artifact = require("../artifacts/contracts/AutoReinvestBotV5.sol/AutoReinvestBotV5.json");
  const contract = new ethers.Contract(address, artifact.abi, signer);

  const config = await contract.getConfig();
  const onChainInterval = Number(config._reinvestIntervalSecs) * 1000;
  const interval = onChainInterval || INTERVAL_MS;
  console.log(`[Bot] Iniciando. Intervalo: ${interval / 1000}s`);

  await reinvest(contract);
  setInterval(() => reinvest(contract), interval);
}

main().catch(e => { console.error(e); process.exit(1); });
