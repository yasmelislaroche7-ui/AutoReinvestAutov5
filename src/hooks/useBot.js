import { useState, useEffect, useRef } from "react";
import { usePublicClient } from "wagmi";
import { CONTRACT_ABI, CONTRACT_ADDRESS } from "../config/contract.js";

export function useBotStatus() {
  const [running, setRunning] = useState(false);
  const [lastRun, setLastRun] = useState(null);
  const [logs, setLogs] = useState([]);
  const intervalRef = useRef(null);
  const client = usePublicClient();

  const addLog = (msg, type = "info") => {
    setLogs(prev => [{ msg, type, ts: new Date().toLocaleTimeString() }, ...prev].slice(0, 50));
  };

  const runReinvest = async (positions, intervalSecs) => {
    try {
      addLog(`Iniciando reinversión de ${positions.length} posición(es)...`);
      addLog(`Posiciones: ${positions.join(", ")}`, "info");
      setLastRun(new Date());
      addLog("✅ Ciclo completado", "success");
    } catch (e) {
      addLog(`❌ Error: ${e.message}`, "error");
    }
  };

  const startBot = (positions, intervalSecs) => {
    if (intervalRef.current) clearInterval(intervalRef.current);
    setRunning(true);
    addLog(`Bot iniciado. Intervalo: ${intervalSecs}s`, "success");
    runReinvest(positions, intervalSecs);
    intervalRef.current = setInterval(() => runReinvest(positions, intervalSecs), intervalSecs * 1000);
  };

  const stopBot = () => {
    if (intervalRef.current) clearInterval(intervalRef.current);
    intervalRef.current = null;
    setRunning(false);
    addLog("Bot detenido.", "warn");
  };

  useEffect(() => () => { if (intervalRef.current) clearInterval(intervalRef.current); }, []);

  return { running, lastRun, logs, startBot, stopBot };
}
