import { useState } from "react";
import { useAccount } from "wagmi";
import { useContractRead, useContractWrite, useIsOwner } from "../hooks/useContract.js";
import BotControl from "../components/BotControl.jsx";
import PositionCard from "../components/PositionCard.jsx";
import ImportModal from "../components/ImportModal.jsx";
import "../styles/Dashboard.css";

export default function Dashboard() {
  const { isConnected, address } = useAccount();
  const isOwner = useIsOwner();
  const { data: positions, refetch: refetchPositions } = useContractRead("getManagedPositions", [], true);
  const { data: config } = useContractRead("getConfig", [], true);
  const { write: writeContract, isPending } = useContractWrite();
  const [showImport, setShowImport] = useState(false);
  const [pauseMsg, setPauseMsg] = useState("");

  const handleTogglePause = async () => {
    if (!config) return;
    try {
      setPauseMsg("Enviando transacción...");
      await writeContract("setPaused", [!config[5]]);
      setPauseMsg(config[5] ? "✅ Contrato reactivado" : "✅ Contrato pausado");
    } catch (e) {
      setPauseMsg(`❌ Error: ${e.shortMessage || e.message}`);
    }
  };

  const handleRemovePosition = async (tokenId) => {
    if (!confirm(`¿Eliminar posición #${tokenId}?`)) return;
    try {
      await writeContract("removePosition", [tokenId]);
      refetchPositions();
    } catch (e) {
      alert(`Error: ${e.shortMessage || e.message}`);
    }
  };

  if (!isConnected) {
    return (
      <div className="dashboard-connect">
        <div className="connect-card">
          <div className="connect-icon">⚡</div>
          <h1>PROYECTO DOLA</h1>
          <h2>AutoReinvest Bot</h2>
          <p>Conecta tu wallet para ver y gestionar tus posiciones de liquidez en World Chain.</p>
          <w3m-button />
        </div>
      </div>
    );
  }

  return (
    <div className="dashboard">
      <div className="dashboard-top">
        <div className="dashboard-title">
          <h1>Panel de Control</h1>
          <span className="chain-badge">🌍 World Chain</span>
        </div>
        <div className="dashboard-actions">
          {isOwner && config && (
            <button
              className={`btn-${config[5] ? "success" : "warning"}`}
              onClick={handleTogglePause}
              disabled={isPending}
            >
              {config[5] ? "▶ Reactivar Contrato" : "⏸ Pausar Contrato"}
            </button>
          )}
          {isOwner && (
            <button className="btn-primary" onClick={() => setShowImport(true)}>
              + Importar Posición
            </button>
          )}
        </div>
      </div>

      {pauseMsg && <div className="banner">{pauseMsg}</div>}

      {config && (
        <div className="stats-bar">
          <div className="stat-chip">
            <span>Contrato</span>
            <strong className={config[5] ? "text-warn" : "text-success"}>
              {config[5] ? "⏸ Pausado" : "▶ Activo"}
            </strong>
          </div>
          <div className="stat-chip">
            <span>Slippage</span>
            <strong>{Number(config[0]) === 0 ? "Sin límite" : `${(Number(config[0]) / 100).toFixed(2)}%`}</strong>
          </div>
          <div className="stat-chip">
            <span>Intervalo</span>
            <strong>{(Number(config[1]) / 60).toFixed(1)} min</strong>
          </div>
          <div className="stat-chip">
            <span>Posiciones</span>
            <strong>{positions?.length ?? 0}</strong>
          </div>
        </div>
      )}

      <BotControl
        positions={positions}
        isOwner={isOwner}
      />

      <div className="positions-section">
        <div className="section-header">
          <h2>Posiciones Gestionadas</h2>
          {isOwner && (
            <button className="btn-secondary btn-sm" onClick={() => setShowImport(true)}>
              + Agregar
            </button>
          )}
        </div>

        {!positions || positions.length === 0 ? (
          <div className="empty-state">
            <p>No hay posiciones gestionadas.</p>
            {isOwner && (
              <button className="btn-primary" onClick={() => setShowImport(true)}>
                Importar primera posición
              </button>
            )}
          </div>
        ) : (
          <div className="positions-grid">
            {positions.map(id => (
              <PositionCard
                key={id.toString()}
                tokenId={id}
                isOwner={isOwner}
                onRemove={handleRemovePosition}
              />
            ))}
          </div>
        )}
      </div>

      {showImport && (
        <ImportModal
          onClose={() => setShowImport(false)}
          onSuccess={refetchPositions}
        />
      )}
    </div>
  );
}
