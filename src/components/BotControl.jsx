import { useState } from "react";
import { useBotStatus } from "../hooks/useBot.js";
import { useContractRead } from "../hooks/useContract.js";
import "../styles/BotControl.css";

export default function BotControl({ positions, isOwner }) {
  const { running, lastRun, logs, startBot, stopBot } = useBotStatus();
  const { data: config } = useContractRead("getConfig", [], true);
  const [customInterval, setCustomInterval] = useState("");

  const intervalSecs = customInterval
    ? parseInt(customInterval)
    : config ? Number(config[1]) : 300;

  const handleToggle = () => {
    if (running) {
      stopBot();
    } else {
      if (!positions || positions.length === 0) {
        alert("No hay posiciones gestionadas. Agrega posiciones primero.");
        return;
      }
      startBot(positions.map(p => p.toString()), intervalSecs);
    }
  };

  return (
    <div className="bot-control">
      <div className="bot-header">
        <div className="bot-title">
          <h2>Bot de Reinversión</h2>
          <span className={`bot-badge ${running ? "running" : "stopped"}`}>
            {running ? "● EN EJECUCIÓN" : "● DETENIDO"}
          </span>
        </div>
        {isOwner && (
          <button
            className={`toggle-btn ${running ? "btn-stop" : "btn-start"}`}
            onClick={handleToggle}
          >
            {running ? "⏹ Detener Bot" : "▶ Iniciar Bot"}
          </button>
        )}
      </div>

      <div className="bot-stats">
        <div className="stat">
          <span className="stat-label">Intervalo on-chain</span>
          <span className="stat-value">{config ? Number(config[1]) : "—"}s</span>
        </div>
        <div className="stat">
          <span className="stat-label">Último reinvest</span>
          <span className="stat-value">
            {config && Number(config[6]) > 0
              ? new Date(Number(config[6]) * 1000).toLocaleString()
              : "Nunca"}
          </span>
        </div>
        <div className="stat">
          <span className="stat-label">Posiciones activas</span>
          <span className="stat-value">{positions?.length ?? 0}</span>
        </div>
      </div>

      {isOwner && (
        <div className="bot-interval">
          <label>Intervalo personalizado (segundos):</label>
          <input
            type="number"
            min="60"
            placeholder={`${intervalSecs}s (default)`}
            value={customInterval}
            onChange={e => setCustomInterval(e.target.value)}
          />
        </div>
      )}

      <div className="bot-logs">
        <h4>Actividad reciente</h4>
        <div className="log-list">
          {logs.length === 0 && <p className="log-empty">Sin actividad aún...</p>}
          {logs.map((l, i) => (
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
