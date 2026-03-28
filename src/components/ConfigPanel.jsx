import { useState } from "react";
import { useContractRead, useContractWrite } from "../hooks/useContract.js";
import "../styles/ConfigPanel.css";

export default function ConfigPanel() {
  const { data: config, refetch } = useContractRead("getConfig", [], true);
  const { write, isPending } = useContractWrite();

  const [slippage, setSlippage] = useState("");
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

  return (
    <div className="config-panel">
      <h3>Configuración del Contrato</h3>
      {msg && <div className="config-msg">{msg}</div>}

      <div className="config-grid">
        <div className="config-item">
          <label>Slippage (0 = sin límite)</label>
          <div className="config-current">Actual: {Number(config[0])} bps ({(Number(config[0]) / 100).toFixed(2)}%)</div>
          <div className="config-input-row">
            <input type="number" min="0" max="10000" placeholder="bps" value={slippage} onChange={e => setSlippage(e.target.value)} />
            <button className="btn-primary btn-sm" onClick={() => apply("setSlippage", [BigInt(slippage)], "Slippage")} disabled={!slippage || isPending}>
              Aplicar
            </button>
          </div>
        </div>

        <div className="config-item">
          <label>Intervalo de reinversión</label>
          <div className="config-current">Actual: {Number(config[1])}s ({(Number(config[1]) / 60).toFixed(1)} min)</div>
          <div className="config-input-row">
            <input type="number" min="60" placeholder="segundos" value={interval} onChange={e => setInterval_(e.target.value)} />
            <button className="btn-primary btn-sm" onClick={() => apply("setReinvestInterval", [BigInt(interval)], "Intervalo")} disabled={!interval || isPending}>
              Aplicar
            </button>
          </div>
        </div>

        <div className="config-item">
          <label>Fee de reserva</label>
          <div className="config-current">Actual: {Number(config[2])} bps ({(Number(config[2]) / 100).toFixed(2)}%)</div>
          <div className="config-input-row">
            <input type="number" min="0" max="2000" placeholder="bps" value={reserve} onChange={e => setReserve(e.target.value)} />
            <button className="btn-primary btn-sm" onClick={() => apply("setReserveFeeBps", [BigInt(reserve)], "Reserva")} disabled={!reserve || isPending}>
              Aplicar
            </button>
          </div>
        </div>

        <div className="config-item">
          <label>Distribución (H2O / BTCH2O / Reinvest)</label>
          <div className="config-current">
            Actual: H2O {(Number(config[3]) / 100).toFixed(0)}% | BTCH2O {(Number(config[4]) / 100).toFixed(0)}% | Reinvest {(10000 - Number(config[3]) - Number(config[4])) / 100}%
          </div>
          <div className="config-input-row">
            <input type="number" min="0" max="10000" placeholder="H2O bps" value={h2oShare} onChange={e => setH2oShare(e.target.value)} />
            <input type="number" min="0" max="10000" placeholder="BTCH2O bps" value={btch2oShare} onChange={e => setBtch2oShare(e.target.value)} />
            <button className="btn-primary btn-sm" onClick={() => apply("setDistribution", [BigInt(h2oShare), BigInt(btch2oShare)], "Distribución")} disabled={!h2oShare || !btch2oShare || isPending}>
              Aplicar
            </button>
          </div>
        </div>
      </div>

      <div className="config-status">
        <div className={`status-badge ${config[5] ? "paused" : "active"}`}>
          Contrato: {config[5] ? "⏸ PAUSADO" : "▶ ACTIVO"}
        </div>
      </div>
    </div>
  );
}
