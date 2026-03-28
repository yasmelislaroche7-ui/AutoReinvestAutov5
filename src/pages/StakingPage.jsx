import { useAccount } from "wagmi";
import StakingPanel from "../components/StakingPanel.jsx";
import "../styles/StakingPage.css";

export default function StakingPage() {
  const { isConnected } = useAccount();

  if (!isConnected) {
    return (
      <div className="staking-page-connect">
        <div className="connect-card">
          <div className="connect-icon">🔒</div>
          <h1>Acua Company Staking</h1>
          <h2>Gana recompensas por hacer stake</h2>
          <p>Conecta tu wallet para ver tus posiciones de staking, depositar, retirar y reclamar recompensas.</p>
          <w3m-button />
        </div>
      </div>
    );
  }

  return (
    <div className="staking-page">
      <div className="staking-page-header">
        <div>
          <h1>🔒 Staking Hub</h1>
          <p className="staking-page-sub">Gestiona tus posiciones de staking y recompensas</p>
        </div>
        <span className="chain-badge">🌍 World Chain</span>
      </div>

      <div className="staking-panels-grid">
        <StakingPanel />
      </div>
    </div>
  );
}
