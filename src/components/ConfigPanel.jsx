import { useState } from "react";
import { useContractRead, useContractWrite } from "../hooks/useContract.js";
import "../styles/ConfigPanel.css";

// getConfig() array indices:
// [0]=reinvestIntervalSecs [1]=reserveFeeBps [2]=h2oShareBps [3]=btch2oShareBps [4]=paused [5]=lastReinvestAt

export default function ConfigPanel() {
  const { data: config, refetch } = useContractRead("getConfig", [], true);
  const { write, isPending } = useContractWrite();

  const [interval, setInterval_] = useState("");
  const [reserve, setReserve] = useState("");
  const [h2oShare, setH2oShare] = useState("");
  const [btch2oShare, setBtch2oShare] = useState("");
  const [msg, setMsg] = useState("");

  const apply = async (fn, args, label) => {
    try {
      setMsg(`Enviando ${label}...`);
      await write(fn, args);
      setMsg(`✅ ${label} actualizado`);
      refetch();
    } catch (e) {
      setMsg(`❌ Error: ${e.shortMessage || e.message}`);
    }
  };

  if (!config) return <div className="config-panel loading">Cargando configuración...</div>;

  const isPaused = config[4];

  return (
    <div className="config-panel">
      <h3>Configuración del Contrato</h3>
      {msg && <div className="config-msg">{msg}</div>}

      <div className="config-status">
        <div className={`status-badge ${isPaused ? "paused" : "active"}`}>
          Contrato: {isPaused ? "⏸ PAUSADO" : "▶ ACTIVO"}
        </div>
        <span className="config-last">
          Último reinvest:{" "}
          {Number(config[5]) > 0
            ? new Date(Number(config[5]) * 1000).toLocaleString()
            : "Nunca"}
        </span>
      </div>

      <div className="config-grid">
        <div className="config-item">
          <label>Intervalo de reinversión</label>
          <div className="config-current">
            Actual: {Number(config[0])}s ({(Number(config[0]) / 60).toFixed(1)} min)
          </div>
          <div className="config-input-row">
            <input
              type="number"
              min="60"
              placeholder="segundos"
              value={interval}
              onChange={e => setInterval_(e.target.value)}
            />
            <button
              className="btn-primary btn-sm"
              onClick={() => apply("setReinvestInterval", [BigInt(interval)], "Intervalo")}
              disabled={!interval || isPending}
            >
              Aplicar
            </button>
          </div>
        </div>

        <div className="config-item">
          <label>Fee de reserva</label>
          <div className="config-current">
            Actual: {Number(config[1])} bps ({(Number(config[1]) / 100).toFixed(2)}%)
          </div>
          <div className="config-input-row">
            <input
              type="number"
              min="0"
              max="2000"
              placeholder="bps (ej: 100 = 1%)"
              value={reserve}
              onChange={e => setReserve(e.target.value)}
            />
            <button
              className="btn-primary btn-sm"
              onClick={() => apply("setReserveFeeBps", [BigInt(reserve)], "Reserva")}
              disabled={!reserve || isPending}
            >
              Aplicar
            </button>
          </div>
        </div>

        <div className="config-item full-width">
          <label>Distribución de fees (H2O / BTCH2O / Reinvest)</label>
          <div className="config-current">
            Actual: H2O {(Number(config[2]) / 100).toFixed(0)}% | BTCH2O {(Number(config[3]) / 100).toFixed(0)}% | Reinvest{" "}
            {((10000 - Number(config[2]) - Number(config[3])) / 100).toFixed(0)}%
          </div>
          <div className="config-input-row">
            <input
              type="number"
              min="0"
              max="10000"
              placeholder="H2O bps"
              value={h2oShare}
              onChange={e => setH2oShare(e.target.value)}
            />
            <input
              type="number"
              min="0"
              max="10000"
              placeholder="BTCH2O bps"
              value={btch2oShare}
              onChange={e => setBtch2oShare(e.target.value)}
            />
            <button
              className="btn-primary btn-sm"
              onClick={() =>
                apply("setDistribution", [BigInt(h2oShare), BigInt(btch2oShare)], "Distribución")
              }
              disabled={!h2oShare || !btch2oShare || isPending}
            >
              Aplicar
            </button>
          </div>
          <p className="config-hint">
            La suma H2O + BTCH2O debe ser ≤ 10000. El resto va a reinversión automática.
          </p>
        </div>
      </div>
    </div>
  );
}
