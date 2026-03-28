import { useState } from "react";
import { useAccount } from "wagmi";
import { useIsOwner, useIsPrimaryOwner } from "../hooks/useContract.js";
import ConfigPanel from "../components/ConfigPanel.jsx";
import ReservePanel from "../components/ReservePanel.jsx";
import OwnersPanel from "../components/OwnersPanel.jsx";
import ImportModal from "../components/ImportModal.jsx";
import { useContractRead } from "../hooks/useContract.js";
import { Link } from "react-router-dom";
import "../styles/OwnerPanel.css";

const TABS = [
  { id: "config", label: "⚙️ Configuración" },
  { id: "positions", label: "📍 Posiciones" },
  { id: "reserves", label: "💰 Reservas" },
  { id: "owners", label: "👥 Owners" },
  { id: "contracts", label: "📄 Contratos" },
];

export default function OwnerPanel() {
  const { isConnected } = useAccount();
  const isOwner = useIsOwner();
  const isPrimary = useIsPrimaryOwner();
  const [tab, setTab] = useState("config");
  const [showImport, setShowImport] = useState(false);

  const { data: positions, refetch } = useContractRead("getManagedPositions", [], true);
  const { data: wld } = useContractRead("WLD");
  const { data: h2o } = useContractRead("H2O");
  const { data: btch2o } = useContractRead("BTCH2O");
  const { data: primary } = useContractRead("primaryOwner");

  if (!isConnected) {
    return (
      <div className="owner-locked">
        <h2>🔒 Acceso Restringido</h2>
        <p>Conecta tu wallet para continuar.</p>
        <w3m-button />
      </div>
    );
  }

  if (!isOwner) {
    return (
      <div className="owner-locked">
        <h2>🔒 Sin Permisos</h2>
        <p>Tu wallet no es owner de este contrato.</p>
        <Link to="/" className="btn-secondary">Volver al Dashboard</Link>
      </div>
    );
  }

  return (
    <div className="owner-panel">
      <div className="owner-header">
        <div>
          <h1>Panel de Owner</h1>
          {isPrimary && <span className="primary-badge">⭐ Primary Owner</span>}
        </div>
        <button className="btn-primary" onClick={() => setShowImport(true)}>
          + Importar Posición
        </button>
      </div>

      <div className="tab-bar">
        {TABS.map(t => (
          <button
            key={t.id}
            className={`tab-btn ${tab === t.id ? "active" : ""}`}
            onClick={() => setTab(t.id)}
          >
            {t.label}
          </button>
        ))}
      </div>

      <div className="tab-content">
        {tab === "config" && <ConfigPanel />}

        {tab === "positions" && (
          <div className="positions-owner">
            <div className="section-header">
              <h3>Posiciones Gestionadas</h3>
              <button className="btn-primary btn-sm" onClick={() => setShowImport(true)}>+ Agregar</button>
            </div>
            {positions?.length === 0 && <p className="empty">Sin posiciones. Importa una para comenzar.</p>}
            <div className="positions-list">
              {positions?.map(id => (
                <div key={id.toString()} className="pos-row">
                  <span>NFT #{id.toString()}</span>
                  <a href={`https://worldscan.org/token/0xec12a9F9a09f50550686363766Cc153D03c27b5e?a=${id.toString()}`} target="_blank" rel="noreferrer" className="btn-secondary btn-xs">
                    Ver en Worldscan
                  </a>
                  <a href={`https://app.uniswap.org/positions/${id.toString()}`} target="_blank" rel="noreferrer" className="btn-secondary btn-xs">
                    Uniswap
                  </a>
                </div>
              ))}
            </div>
          </div>
        )}

        {tab === "reserves" && <ReservePanel />}

        {tab === "owners" && <OwnersPanel />}

        {tab === "contracts" && (
          <div className="contracts-info">
            <h3>Información del Contrato</h3>
            <div className="info-grid">
              <div className="info-item">
                <label>Bot Contract (AutoReinvestBotV5)</label>
                <a href="https://worldscan.org/address/0x618B521C3d7DAD1a2F186aD830E69ba6d5081E1E" target="_blank" rel="noreferrer">
                  0x618B521C3d7DAD1a2F186aD830E69ba6d5081E1E
                </a>
              </div>
              <div className="info-item">
                <label>Primary Owner</label>
                <a href={`https://worldscan.org/address/${primary}`} target="_blank" rel="noreferrer">
                  {primary}
                </a>
              </div>
              <div className="info-item">
                <label>Token WLD</label>
                <a href={`https://worldscan.org/token/${wld}`} target="_blank" rel="noreferrer">{wld}</a>
              </div>
              <div className="info-item">
                <label>Token H2O</label>
                <a href={`https://worldscan.org/token/${h2o}`} target="_blank" rel="noreferrer">{h2o}</a>
              </div>
              <div className="info-item">
                <label>Token BTCH2O</label>
                <a href={`https://worldscan.org/token/${btch2o}`} target="_blank" rel="noreferrer">{btch2o}</a>
              </div>
              <div className="info-item">
                <label>Position Manager (Uniswap V3)</label>
                <a href="https://worldscan.org/address/0xec12a9F9a09f50550686363766Cc153D03c27b5e" target="_blank" rel="noreferrer">
                  0xec12a9F9a09f50550686363766Cc153D03c27b5e
                </a>
              </div>
              <div className="info-item">
                <label>Swap Router</label>
                <a href="https://worldscan.org/address/0x091AD9e2e6e5eD44c1c66dB50e49A601F9f36cF6" target="_blank" rel="noreferrer">
                  0x091AD9e2e6e5eD44c1c66dB50e49A601F9f36cF6
                </a>
              </div>
              <div className="info-item">
                <label>Network</label>
                <span>World Chain (Chain ID: 480)</span>
              </div>
            </div>

            <div className="external-links">
              <h4>Links útiles</h4>
              <a href="https://worldscan.org/address/0x618B521C3d7DAD1a2F186aD830E69ba6d5081E1E#code" target="_blank" rel="noreferrer" className="btn-secondary">
                Ver código en Worldscan
              </a>
              <a href="https://app.uniswap.org/positions" target="_blank" rel="noreferrer" className="btn-secondary">
                Mis posiciones en Uniswap
              </a>
            </div>
          </div>
        )}
      </div>

      {showImport && (
        <ImportModal
          onClose={() => setShowImport(false)}
          onSuccess={refetch}
        />
      )}
    </div>
  );
}
