import { formatUnits } from "viem";
import { useContractRead } from "../hooks/useContract.js";
import { useContractWrite } from "../hooks/useContract.js";
import "../styles/PositionCard.css";

const SHORT = (addr) => addr ? `${addr.slice(0, 6)}...${addr.slice(-4)}` : "—";

export default function PositionCard({ tokenId, onRemove, isOwner }) {
  const { data: pos, isLoading } = useContractRead("getPosition", [tokenId], true);
  const { write, isPending } = useContractWrite();
  const [collectMsg, setCollectMsg] = [null, () => {}];

  if (isLoading) {
    return (
      <div className="position-card loading">
        <div className="position-loading-text">Cargando #{tokenId.toString()}...</div>
      </div>
    );
  }

  if (!pos) return null;

  const fees0 = pos.tokensOwed0 ? parseFloat(formatUnits(pos.tokensOwed0, 18)) : 0;
  const fees1 = pos.tokensOwed1 ? parseFloat(formatUnits(pos.tokensOwed1, 18)) : 0;
  const hasFees = fees0 > 0.000001 || fees1 > 0.000001;
  const liquidity = pos.liquidity?.toString() ?? "0";
  const hasLiquidity = liquidity !== "0";

  return (
    <div className={`position-card ${pos.isInRange ? "in-range" : "out-range"}`}>
      <div className="position-header">
        <div className="position-id-group">
          <span className="position-id">NFT #{tokenId.toString()}</span>
          {hasFees && <span className="fees-dot" title="Fees sin reclamar">●</span>}
        </div>
        <span className={`range-badge ${pos.isInRange ? "in" : "out"}`}>
          {pos.isInRange ? "✅ En Rango" : "❌ Fuera de Rango"}
        </span>
      </div>

      <div className="position-pool">
        <div className="pool-tokens">
          <a
            className="token-pill"
            href={`https://worldscan.org/token/${pos.token0}`}
            target="_blank"
            rel="noreferrer"
          >
            {SHORT(pos.token0)}
          </a>
          <span className="pool-sep">↔</span>
          <a
            className="token-pill"
            href={`https://worldscan.org/token/${pos.token1}`}
            target="_blank"
            rel="noreferrer"
          >
            {SHORT(pos.token1)}
          </a>
        </div>
        {pos.fee && (
          <span className="fee-tier">{(Number(pos.fee) / 10000).toFixed(2)}%</span>
        )}
      </div>

      <div className="position-details">
        <div className="detail-row">
          <span>Liquidez</span>
          <span className={hasLiquidity ? "" : "text-warn"}>
            {hasLiquidity ? liquidity.slice(0, 10) + (liquidity.length > 10 ? "..." : "") : "Sin liquidez"}
          </span>
        </div>
        <div className="detail-row fees-row">
          <span>Fees pendientes</span>
          <div className="fees-values">
            <span className={hasFees ? "fee-value has-fees" : "fee-value"}>
              {fees0.toFixed(6)}
            </span>
            <span className="fees-sep">/</span>
            <span className={hasFees ? "fee-value has-fees" : "fee-value"}>
              {fees1.toFixed(6)}
            </span>
          </div>
        </div>
      </div>

      <div className="position-actions">
        <a
          href={`https://app.uniswap.org/positions/${tokenId.toString()}`}
          target="_blank"
          rel="noreferrer"
          className="btn-secondary btn-sm"
        >
          Uniswap ↗
        </a>
        <a
          href={`https://worldscan.org/token/0xec12a9F9a09f50550686363766Cc153D03c27b5e?a=${tokenId.toString()}`}
          target="_blank"
          rel="noreferrer"
          className="btn-secondary btn-sm"
        >
          Explorer ↗
        </a>
        {isOwner && (
          <button
            className="btn-danger btn-sm"
            onClick={() => onRemove(tokenId)}
          >
            Quitar
          </button>
        )}
      </div>
    </div>
  );
}
