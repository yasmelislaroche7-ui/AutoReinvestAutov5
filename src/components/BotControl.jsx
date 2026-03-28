import { useState, useEffect } from "react";
import { useBotStatus } from "../hooks/useBot.js";
import { useContractRead } from "../hooks/useContract.js";
import "../styles/BotControl.css";

const MAX_VISIBLE_LOGS = 10;

export default function BotControl({ positions, isOwner }) {
  const {
    running, lastRun, logs,
    totalFees0, totalFees1, inRangeCount,
    startBot, stopBot,
    runManualCollect, runManualClaim,
    refreshFees,
  } = useBotStatus();

  const { data: config } = useContractRead("getConfig", [], true);
  const [customInterval, setCustomInterval] = useState("");
  const [actionMsg, setActionMsg] = useState("");

  const intervalSecs = customInterval
    ? parseInt(customInterval)
    : config ? Number(config[1]) : 300;

  useEffect(() => {
    if (positions?.length) refreshFees(positions);
  }, [positions?.length]);

  const handleToggle = () => {
    if (running) {
      stopBot();
    } else {
      if (!positions || positions.length === 0) {
        alert("No hay posiciones gestionadas. Agrega posiciones primero.");
        return;
      }
      startBot(positions, intervalSecs);
    }
  };

  const handleManualReinvest = async () => {
    if (!positions?.length) return;
    setActionMsg("Reinvirtiendo...");
    await runManualCollect(positions);
    setActionMsg("");
  };

  const handleManualClaim = async () => {
    setActionMsg("Reclamando...");
    await runManualClaim();
    setActionMsg("");
  };

  const visibleLogs = logs.slice(0, MAX_VISIBLE_LOGS);

  return (
    <div className="bot-control">
      <div className="bot-header">
        <div className="bot-title">
          <h2>🤖 Bot de Reinversión</h2>
          <span className={`bot-badge ${running ? "running" : "stopped"}`}>
            {running ? "● EN EJECUCIÓN" : "● DETENIDO"}
          </span>
        </div>
        <div className="bot-header-actions">
          {isOwner && (
            <button
              className={`toggle-btn ${running ? "btn-stop" : "btn-start"}`}
              onClick={handleToggle}
            >
              {running ? "⏹ Detener Bot" : "▶ Iniciar Bot"}
            </button>
          )}
        </div>
      </div>

      <div className="bot-fees-summary">
        <div className="fee-chip">
          <span>Posiciones en Rango</span>
          <strong className={inRangeCount > 0 ? "text-success" : "text-warn"}>
            {inRangeCount} / {positions?.length ?? 0}
          </strong>
        </div>
        <div className="fee-chip">
          <span>Fees Token 0 Sin Reclamar</span>
          <strong className="text-accent">{totalFees0.toFixed(6)}</strong>
        </div>
        <div className="fee-chip">
          <span>Fees Token 1 Sin Reclamar</span>
          <strong className="text-accent">{totalFees1.toFixed(6)}</strong>
        </div>
        <div className="fee-chip">
          <span>Último Reinvest</span>
          <strong>
            {config && Number(config[6]) > 0
              ? new Date(Number(config[6]) * 1000).toLocaleTimeString()
              : "Nunca"}
          </strong>
        </div>
      </div>

      <div className="manual-actions">
        <button
          className="btn-primary manual-btn"
          onClick={handleManualReinvest}
          disabled={!positions?.length || !!actionMsg}
          title="Recolectar fees y reinvertir ahora"
        >
          ⚡ Reinvertir Ahora
        </button>
        <button
          className="btn-success manual-btn"
          onClick={handleManualClaim}
          disabled={!!actionMsg}
          title="Reclamar recompensas de staking TIME"
        >
          🏆 Reclamar TIME
        </button>
        {actionMsg && <span className="action-msg">{actionMsg}</span>}
      </div>

      {isOwner && (
        <div className="bot-interval">
          <label>Intervalo del bot (seg):</label>
          <input
            type="number"
            min="60"
            placeholder={`${intervalSecs}s`}
            value={customInterval}
            onChange={e => setCustomInterval(e.target.value)}
          />
        </div>
      )}

      <div className="bot-logs">
        <div className="bot-logs-header">
          <h4>Últimas 10 actividades</h4>
          <span className="log-count">{logs.length} total</span>
        </div>
        <div className="log-list">
          {visibleLogs.length === 0 && (
            <p className="log-empty">Sin actividad aún. Inicia el bot o usa las acciones manuales.</p>
          )}
          {visibleLogs.map((l, i) => (
            <div key={i} className={`log-entry log-${l.type}`}>
              <span className="log-ts">{l.ts}</span>
              <span className="log-msg">{l.msg}</span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
