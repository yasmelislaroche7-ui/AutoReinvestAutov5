import { useState } from "react";
import { useAccount } from "wagmi";
import { useContractRead, useContractWrite, useIsOwner } from "../hooks/useContract.js";
import BotControl from "../components/BotControl.jsx";
import PositionCard from "../components/PositionCard.jsx";
import ImportModal from "../components/ImportModal.jsx";
import "../styles/Dashboard.css";

// getConfig() returns array:
// [0]=reinvestIntervalSecs [1]=reserveFeeBps [2]=h2oShareBps [3]=btch2oShareBps [4]=paused [5]=lastReinvestAt

export default function Dashboard() {
  const { isConnected } = useAccount();
  const isOwner = useIsOwner();
  const { data: positions, refetch: refetchPositions } = useContractRead("getManagedPositions", [], true);
  const { data: config } = useContractRead("getConfig", [], true);
  const { write: writeContract, isPending } = useContractWrite();
  const [showImport, setShowImport] = useState(false);
  const [pauseMsg, setPauseMsg] = useState("");

  const isPaused = config?.[4] ?? false;

  const handleTogglePause = async () => {
    if (!config) return;
    try {
      setPauseMsg("Enviando transacción...");
      await writeContract("setPaused", [!isPaused]);
      setPauseMsg(isPaused ? "✅ Contrato reactivado" : "✅ Contrato pausado");
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
          <div className="connect-icon">💧</div>
          <h1>Acua Company</h1>
          <h2>AutoReinvest Bot · World Chain</h2>
          <p>
            Conecta tu wallet para ver y gestionar tus posiciones de liquidez,
            hacer stake y reinvertir recompensas automáticamente.
          </p>
          <w3m-button />
          <div className="connect-features">
            <div className="connect-feature"><span>⚡</span><p>Reinversión automática</p></div>
            <div className="connect-feature"><span>🔒</span><p>Staking con APR</p></div>
            <div className="connect-feature"><span>📊</span><p>Monitoreo en tiempo real</p></div>
          </div>
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
          {config && (
            <span className={`status-badge ${isPaused ? "paused" : "active"}`}>
              {isPaused ? "⏸ Pausado" : "● Activo"}
            </span>
          )}
        </div>
        <div className="dashboard-actions">
          {isOwner && config && (
            <button
              className={`btn-${isPaused ? "success" : "warning"}`}
              onClick={handleTogglePause}
              disabled={isPending}
            >
              {isPaused ? "▶ Reactivar" : "⏸ Pausar"}
            </button>
          )}
          {isOwner && (
            <button className="btn-primary" onClick={() => setShowImport(true)}>
              + Importar Posición
            </button>
          )}
        </div>
      </div>

      {pauseMsg && (
        <div className={`banner ${pauseMsg.startsWith("✅") ? "banner-success" : "banner-error"}`}>
          {pauseMsg}
        </div>
      )}

      {config && (
        <div className="stats-bar">
          <div className="stat-chip">
            <span>Estado</span>
            <strong className={isPaused ? "text-warn" : "text-success"}>
              {isPaused ? "⏸ Pausado" : "● Activo"}
            </strong>
          </div>
          <div className="stat-chip">
            <span>Intervalo</span>
            <strong>{(Number(config[0]) / 60).toFixed(1)} min</strong>
          </div>
          <div className="stat-chip">
            <span>Reserva</span>
            <strong>{(Number(config[1]) / 100).toFixed(1)}%</strong>
          </div>
          <div className="stat-chip">
            <span>H2O / BTCH2O</span>
            <strong>{(Number(config[2]) / 100).toFixed(0)}% / {(Number(config[3]) / 100).toFixed(0)}%</strong>
          </div>
          <div className="stat-chip">
            <span>Posiciones</span>
            <strong>{positions?.length ?? 0}</strong>
          </div>
          <div className="stat-chip">
            <span>Último Reinvest</span>
            <strong className="text-sm">
              {Number(config[5]) > 0
                ? new Date(Number(config[5]) * 1000).toLocaleTimeString()
                : "Nunca"}
            </strong>
          </div>
        </div>
      )}

      <BotControl positions={positions} isOwner={isOwner} />

      <div className="positions-section">
        <div className="section-header">
          <h2>Posiciones Uniswap V3</h2>
          {isOwner && (
            <button className="btn-secondary btn-sm" onClick={() => setShowImport(true)}>
              + Agregar
            </button>
          )}
        </div>

        {!positions || positions.length === 0 ? (
          <div className="empty-state">
            <div className="empty-icon">📭</div>
            <p>No hay posiciones gestionadas por el bot.</p>
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
        <ImportModal onClose={() => setShowImport(false)} onSuccess={refetchPositions} />
      )}
    </div>
  );
}
