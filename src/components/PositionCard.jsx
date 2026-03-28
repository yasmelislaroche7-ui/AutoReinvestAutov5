import { formatUnits } from "viem";
import { useContractRead } from "../hooks/useContract.js";
import "../styles/PositionCard.css";

const SHORT = (addr) => addr ? `${addr.slice(0,6)}...${addr.slice(-4)}` : "—";

export default function PositionCard({ tokenId, onRemove, isOwner }) {
  const { data: pos, isLoading } = useContractRead("getPosition", [tokenId], true);

  if (isLoading) return <div className="position-card loading">Cargando #{tokenId.toString()}...</div>;
  if (!pos) return null;

  const fees0 = pos.tokensOwed0 ? formatUnits(pos.tokensOwed0, 18) : "0";
  const fees1 = pos.tokensOwed1 ? formatUnits(pos.tokensOwed1, 18) : "0";

  return (
    <div className={`position-card ${pos.isInRange ? "in-range" : "out-range"}`}>
      <div className="position-header">
        <span className="position-id">NFT #{tokenId.toString()}</span>
        <span className={`range-badge ${pos.isInRange ? "in" : "out"}`}>
          {pos.isInRange ? "✅ En Rango" : "❌ Fuera de Rango"}
        </span>
      </div>

      <div className="position-details">
        <div className="detail-row">
          <span>Token 0:</span>
          <a href={`https://worldscan.org/token/${pos.token0}`} target="_blank" rel="noreferrer">
            {SHORT(pos.token0)}
          </a>
        </div>
        <div className="detail-row">
          <span>Token 1:</span>
          <a href={`https://worldscan.org/token/${pos.token1}`} target="_blank" rel="noreferrer">
            {SHORT(pos.token1)}
          </a>
        </div>
        <div className="detail-row">
          <span>Fee tier:</span>
          <span>{pos.fee ? `${Number(pos.fee) / 10000}%` : "—"}</span>
        </div>
        <div className="detail-row">
          <span>Liquidez:</span>
          <span>{pos.liquidity?.toString() ?? "—"}</span>
        </div>
        <div className="detail-row">
          <span>Fees pendientes:</span>
          <span>{parseFloat(fees0).toFixed(4)} / {parseFloat(fees1).toFixed(4)}</span>
        </div>
      </div>

      {isOwner && (
        <div className="position-actions">
          <button className="btn-danger btn-sm" onClick={() => onRemove(tokenId)}>
            Eliminar
          </button>
          <a
            href={`https://app.uniswap.org/positions/${tokenId.toString()}`}
            target="_blank"
            rel="noreferrer"
            className="btn-secondary btn-sm"
          >
            Ver en Uniswap
          </a>
        </div>
      )}
    </div>
  );
}
