import { useState, useEffect, useRef } from "react";
import { usePublicClient, useWriteContract, useAccount } from "wagmi";
import { formatUnits } from "viem";
import { CONTRACT_ABI, CONTRACT_ADDRESS } from "../config/contract.js";

const MAX_LOGS = 50;
const deadline = () => BigInt(Math.floor(Date.now() / 1000) + 600);

export function useBotStatus() {
  const [running, setRunning] = useState(false);
  const [lastRun, setLastRun] = useState(null);
  const [logs, setLogs] = useState([]);
  const [totalFees0, setTotalFees0] = useState(0);
  const [totalFees1, setTotalFees1] = useState(0);
  const [inRangeCount, setInRangeCount] = useState(0);
  const intervalRef = useRef(null);
  const client = usePublicClient();
  const { writeContractAsync } = useWriteContract();
  const { address } = useAccount();

  const addLog = (msg, type = "info") => {
    setLogs(prev => [{ msg, type, ts: new Date().toLocaleTimeString() }, ...prev].slice(0, MAX_LOGS));
  };

  // viem returns arrays for multi-output functions — use numeric indices
  const readPositionFees = async (positions) => {
    if (!client || !positions?.length) return { fees0: 0, fees1: 0, inRange: 0 };
    let total0 = 0, total1 = 0, inRangeN = 0;
    for (const tokenId of positions) {
      try {
        const pos = await client.readContract({
          address: CONTRACT_ADDRESS,
          abi: CONTRACT_ABI,
          functionName: "getPosition",
          args: [BigInt(tokenId.toString())],
        });
        if (pos) {
          // pos[6] = tokensOwed0, pos[7] = tokensOwed1, pos[9] = isInRange
          const f0 = parseFloat(formatUnits(pos[6] ?? 0n, 18));
          const f1 = parseFloat(formatUnits(pos[7] ?? 0n, 18));
          total0 += f0;
          total1 += f1;
          if (pos[9]) inRangeN++;
        }
      } catch (e) {
        addLog(`⚠️ Error leyendo pos #${tokenId}: ${e.shortMessage || e.message}`, "warn");
      }
    }
    return { fees0: total0, fees1: total1, inRange: inRangeN };
  };

  const runReinvest = async (positions) => {
    try {
      addLog(`🔍 Escaneando ${positions.length} posición(es)...`);

      const { fees0, fees1, inRange } = await readPositionFees(positions);
      setTotalFees0(fees0);
      setTotalFees1(fees1);
      setInRangeCount(inRange);

      addLog(`📊 En rango: ${inRange}/${positions.length} | Fees: ${fees0.toFixed(6)} / ${fees1.toFixed(6)}`);

      if (!address) {
        addLog("⚠️ Wallet no conectada. No se puede ejecutar.", "warn");
        return;
      }

      // config[4] = paused
      const config = await client.readContract({
        address: CONTRACT_ADDRESS,
        abi: CONTRACT_ABI,
        functionName: "getConfig",
      });

      if (config && config[4]) {
        addLog("⏸ Contrato pausado, reinversión omitida.", "warn");
        return;
      }

      addLog("⚡ Ejecutando collectAll...", "info");
      // collectAll(uint256[] tokenIds, uint256 deadline)
      const ids = positions.map(p => BigInt(p.toString()));
      const tx = await writeContractAsync({
        address: CONTRACT_ADDRESS,
        abi: CONTRACT_ABI,
        functionName: "collectAll",
        args: [ids, deadline()],
      });
      addLog(`✅ Tx: ${tx.slice(0, 10)}...${tx.slice(-6)}`, "success");
      setLastRun(new Date());
    } catch (e) {
      const msg = e.shortMessage || e.message || "Error desconocido";
      addLog(`❌ Error: ${msg}`, "error");
    }
  };

  const runManualCollect = async (positions) => {
    addLog("🖐 Reinversión manual iniciada...", "info");
    await runReinvest(positions);
  };

  const runManualClaim = async () => {
    try {
      addLog("🏆 Reclamando recompensas TIME...", "info");
      // claimStakingRewards(uint256 deadline)
      const tx = await writeContractAsync({
        address: CONTRACT_ADDRESS,
        abi: CONTRACT_ABI,
        functionName: "claimStakingRewards",
        args: [deadline()],
      });
      addLog(`✅ Claim enviado: ${tx.slice(0, 10)}...${tx.slice(-6)}`, "success");
    } catch (e) {
      const msg = e.shortMessage || e.message || "Error desconocido";
      addLog(`❌ Claim error: ${msg}`, "error");
    }
  };

  const refreshFees = async (positions) => {
    if (!positions?.length) return;
    const { fees0, fees1, inRange } = await readPositionFees(positions);
    setTotalFees0(fees0);
    setTotalFees1(fees1);
    setInRangeCount(inRange);
  };

  const startBot = (positions, intervalSecs) => {
    if (intervalRef.current) clearInterval(intervalRef.current);
    setRunning(true);
    addLog(`🤖 Bot iniciado. Intervalo: ${intervalSecs}s`, "success");
    runReinvest(positions);
    intervalRef.current = setInterval(() => runReinvest(positions), intervalSecs * 1000);
  };

  const stopBot = () => {
    if (intervalRef.current) clearInterval(intervalRef.current);
    intervalRef.current = null;
    setRunning(false);
    addLog("⏹ Bot detenido.", "warn");
  };

  useEffect(() => () => { if (intervalRef.current) clearInterval(intervalRef.current); }, []);

  return {
    running, lastRun, logs,
    totalFees0, totalFees1, inRangeCount,
    startBot, stopBot,
    runManualCollect, runManualClaim, refreshFees,
  };
}
