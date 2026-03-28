import { useState } from "react";
import { useAccount, useReadContract, useWriteContract, useWaitForTransactionReceipt } from "wagmi";
import { formatUnits, parseUnits } from "viem";
import { ACUA_STAKING_ADDRESS, STAKING_ABI, ERC20_ABI } from "../config/staking.js";
import { CONTRACT_ABI, CONTRACT_ADDRESS } from "../config/contract.js";
import "../styles/StakingPanel.css";

const MAXUINT = BigInt("0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff");

function fmt(val, dec = 18, dp = 4) {
  if (val === undefined || val === null) return "—";
  try { return parseFloat(formatUnits(BigInt(val.toString()), dec)).toFixed(dp); } catch { return "—"; }
}

function ERC20ApproveBtn({ tokenAddress, spender, label, onDone }) {
  const { writeContractAsync, isPending } = useWriteContract();
  const [hash, setHash] = useState(null);
  const { isLoading } = useWaitForTransactionReceipt({ hash });

  const handleApprove = async () => {
    try {
      const tx = await writeContractAsync({
        address: tokenAddress,
        abi: ERC20_ABI,
        functionName: "approve",
        args: [spender, MAXUINT],
      });
      setHash(tx);
      if (onDone) setTimeout(onDone, 3000);
    } catch {}
  };

  return (
    <button className="btn-primary staking-btn" onClick={handleApprove} disabled={isPending || isLoading}>
      {isPending || isLoading ? "Aprobando..." : label || "Aprobar Token"}
    </button>
  );
}

function AcuaStakingCard() {
  const { address, isConnected } = useAccount();
  const userAddr = address ?? "0x0000000000000000000000000000000000000000";

  const { data: stakingToken } = useReadContract({ address: ACUA_STAKING_ADDRESS, abi: STAKING_ABI, functionName: "stakingToken", query: { staleTime: 60000 } });
  const { data: apr } = useReadContract({ address: ACUA_STAKING_ADDRESS, abi: STAKING_ABI, functionName: "apr", query: { refetchInterval: 60000 } });
  const { data: stakedBalance, refetch: refetchStaked } = useReadContract({ address: ACUA_STAKING_ADDRESS, abi: STAKING_ABI, functionName: "stakedBalance", args: [userAddr], query: { refetchInterval: 12000, enabled: !!address } });
  const { data: pendingRewards, refetch: refetchRewards } = useReadContract({ address: ACUA_STAKING_ADDRESS, abi: STAKING_ABI, functionName: "pendingRewards", args: [userAddr], query: { refetchInterval: 12000, enabled: !!address } });

  const minimalERC20 = [
    { inputs: [], name: "symbol", outputs: [{ type: "string" }], stateMutability: "view", type: "function" },
    { inputs: [{ name: "account", type: "address" }], name: "balanceOf", outputs: [{ type: "uint256" }], stateMutability: "view", type: "function" },
    { inputs: [], name: "decimals", outputs: [{ type: "uint8" }], stateMutability: "view", type: "function" },
    { inputs: [{ name: "owner", type: "address" }, { name: "spender", type: "address" }], name: "allowance", outputs: [{ type: "uint256" }], stateMutability: "view", type: "function" },
  ];

  const { data: tokenSymbol } = useReadContract({ address: stakingToken, abi: minimalERC20, functionName: "symbol", query: { enabled: !!stakingToken } });
  const { data: tokenBalance, refetch: refetchBalance } = useReadContract({ address: stakingToken, abi: minimalERC20, functionName: "balanceOf", args: [userAddr], query: { refetchInterval: 12000, enabled: !!stakingToken && !!address } });
  const { data: tokenDecimals } = useReadContract({ address: stakingToken, abi: minimalERC20, functionName: "decimals", query: { enabled: !!stakingToken } });
  const { data: allowance, refetch: refetchAllowance } = useReadContract({ address: stakingToken, abi: minimalERC20, functionName: "allowance", args: [userAddr, ACUA_STAKING_ADDRESS], query: { refetchInterval: 12000, enabled: !!stakingToken && !!address } });

  const { writeContractAsync, isPending } = useWriteContract();
  const [hash, setHash] = useState(null);
  const { isLoading: isConfirming } = useWaitForTransactionReceipt({ hash });
  const [stakeAmt, setStakeAmt] = useState("");
  const [unstakeAmt, setUnstakeAmt] = useState("");
  const [msg, setMsg] = useState("");

  const dec = Number(tokenDecimals ?? 18);
  const busy = isPending || isConfirming;

  const refetchAll = () => { refetchStaked(); refetchRewards(); refetchBalance(); refetchAllowance(); };

  const needsApproval = (amtStr) => {
    if (!allowance || !amtStr) return false;
    try { return allowance < parseUnits(amtStr, dec); } catch { return false; }
  };

  const exec = async (fn) => {
    try {
      const tx = await fn();
      setHash(tx);
      setTimeout(refetchAll, 3000);
    } catch (e) {
      setMsg(`❌ ${e.shortMessage || e.message}`);
    }
  };

  const handleStake = () => exec(async () => {
    setMsg("Haciendo stake...");
    const tx = await writeContractAsync({ address: ACUA_STAKING_ADDRESS, abi: STAKING_ABI, functionName: "stake", args: [parseUnits(stakeAmt, dec)] });
    setMsg("✅ Stake exitoso");
    setStakeAmt("");
    return tx;
  });

  const handleUnstake = () => exec(async () => {
    setMsg("Retirando stake...");
    const tx = await writeContractAsync({ address: ACUA_STAKING_ADDRESS, abi: STAKING_ABI, functionName: "unstake", args: [parseUnits(unstakeAmt, dec)] });
    setMsg("✅ Retiro exitoso");
    setUnstakeAmt("");
    return tx;
  });

  const handleClaim = () => exec(async () => {
    setMsg("Reclamando recompensas...");
    const tx = await writeContractAsync({ address: ACUA_STAKING_ADDRESS, abi: STAKING_ABI, functionName: "claim", args: [] });
    setMsg("✅ Recompensas reclamadas");
    return tx;
  });

  if (!isConnected) {
    return <p className="staking-connect-hint">Conecta tu wallet para gestionar tu ACUA stake.</p>;
  }

  const aprPct = apr ? (Number(apr) / 100).toFixed(2) : "—";

  return (
    <div className="staking-card">
      <div className="staking-card-header">
        <h3>ACUA Staking</h3>
        <span className="staking-label">Earn APR</span>
      </div>

      {msg && (
        <div className={`staking-msg ${msg.startsWith("✅") ? "success" : msg.startsWith("❌") ? "error" : "info"}`}>
          {msg}
        </div>
      )}

      <div className="staking-stats">
        <div className="staking-stat">
          <span>APR</span>
          <strong className="text-success">{aprPct}%</strong>
        </div>
        <div className="staking-stat">
          <span>Tu Stake</span>
          <strong>{fmt(stakedBalance, dec)} {tokenSymbol ?? "—"}</strong>
        </div>
        <div className="staking-stat">
          <span>Recompensas</span>
          <strong className="text-accent">{fmt(pendingRewards, dec)}</strong>
        </div>
        <div className="staking-stat">
          <span>Balance Wallet</span>
          <strong>{fmt(tokenBalance, dec)} {tokenSymbol ?? "—"}</strong>
        </div>
      </div>

      <div className="staking-actions">
        <div className="staking-section">
          <label>Depositar (Stake)</label>
          <div className="staking-input-row">
            <input type="number" min="0" placeholder={`Cantidad ${tokenSymbol ?? ""}`} value={stakeAmt} onChange={e => setStakeAmt(e.target.value)} disabled={busy} />
            <button className="btn-sm btn-secondary" onClick={() => tokenBalance && setStakeAmt(fmt(tokenBalance, dec, 6))} disabled={!tokenBalance}>Max</button>
          </div>
          {stakeAmt && needsApproval(stakeAmt) ? (
            <ERC20ApproveBtn tokenAddress={stakingToken} spender={ACUA_STAKING_ADDRESS} onDone={refetchAllowance} />
          ) : (
            <button className="btn-primary staking-btn" onClick={handleStake} disabled={busy || !stakeAmt}>
              {busy ? "Procesando..." : "Depositar"}
            </button>
          )}
        </div>

        <div className="staking-section">
          <label>Retirar (Unstake)</label>
          <div className="staking-input-row">
            <input type="number" min="0" placeholder={`Cantidad ${tokenSymbol ?? ""}`} value={unstakeAmt} onChange={e => setUnstakeAmt(e.target.value)} disabled={busy} />
            <button className="btn-sm btn-secondary" onClick={() => stakedBalance && setUnstakeAmt(fmt(stakedBalance, dec, 6))} disabled={!stakedBalance}>Max</button>
          </div>
          <button className="btn-warning staking-btn" onClick={handleUnstake} disabled={busy || !unstakeAmt}>
            {busy ? "Procesando..." : "Retirar"}
          </button>
        </div>

        <div className="staking-section staking-claim">
          <div className="claim-info">
            <span>Recompensas disponibles</span>
            <strong className="text-success">{fmt(pendingRewards, dec)} {tokenSymbol ?? ""}</strong>
          </div>
          <button className="btn-success staking-claim-btn" onClick={handleClaim} disabled={busy || !pendingRewards || pendingRewards === 0n}>
            {busy ? "..." : "Reclamar"}
          </button>
        </div>
      </div>

      <div className="staking-footer">
        <a href={`https://worldscan.org/address/${ACUA_STAKING_ADDRESS}`} target="_blank" rel="noreferrer" className="staking-link">Ver contrato ↗</a>
        {stakingToken && <a href={`https://worldscan.org/token/${stakingToken}`} target="_blank" rel="noreferrer" className="staking-link">Ver token {tokenSymbol} ↗</a>}
      </div>
    </div>
  );
}

function TimeStakingCard() {
  const { address, isConnected } = useAccount();
  const userAddr = address ?? "0x0000000000000000000000000000000000000000";

  const { data: timeToken } = useReadContract({ address: CONTRACT_ADDRESS, abi: CONTRACT_ABI, functionName: "TIME_TOKEN", query: { staleTime: 60000 } });
  const { data: stakingInfo, refetch: refetchInfo } = useReadContract({ address: CONTRACT_ADDRESS, abi: CONTRACT_ABI, functionName: "getStakingInfo", query: { refetchInterval: 12000 } });
  const { data: pendingReward, refetch: refetchPending } = useReadContract({ address: CONTRACT_ADDRESS, abi: CONTRACT_ABI, functionName: "pendingStakingReward", query: { refetchInterval: 12000 } });
  const { data: stakedBalance, refetch: refetchStaked } = useReadContract({ address: CONTRACT_ADDRESS, abi: CONTRACT_ABI, functionName: "stakedTimeBalance", query: { refetchInterval: 12000 } });

  const minimalERC20 = [
    { inputs: [], name: "symbol", outputs: [{ type: "string" }], stateMutability: "view", type: "function" },
    { inputs: [{ name: "account", type: "address" }], name: "balanceOf", outputs: [{ type: "uint256" }], stateMutability: "view", type: "function" },
    { inputs: [], name: "decimals", outputs: [{ type: "uint8" }], stateMutability: "view", type: "function" },
    { inputs: [{ name: "owner", type: "address" }, { name: "spender", type: "address" }], name: "allowance", outputs: [{ type: "uint256" }], stateMutability: "view", type: "function" },
  ];

  const { data: tokenSymbol } = useReadContract({ address: timeToken, abi: minimalERC20, functionName: "symbol", query: { enabled: !!timeToken } });
  const { data: tokenBalance, refetch: refetchBalance } = useReadContract({ address: timeToken, abi: minimalERC20, functionName: "balanceOf", args: [userAddr], query: { refetchInterval: 12000, enabled: !!timeToken && !!address } });
  const { data: tokenDecimals } = useReadContract({ address: timeToken, abi: minimalERC20, functionName: "decimals", query: { enabled: !!timeToken } });
  const { data: allowance, refetch: refetchAllowance } = useReadContract({ address: timeToken, abi: minimalERC20, functionName: "allowance", args: [userAddr, CONTRACT_ADDRESS], query: { refetchInterval: 12000, enabled: !!timeToken && !!address } });

  const { writeContractAsync, isPending } = useWriteContract();
  const [hash, setHash] = useState(null);
  const { isLoading: isConfirming } = useWaitForTransactionReceipt({ hash });
  const [stakeAmt, setStakeAmt] = useState("");
  const [unstakeAmt, setUnstakeAmt] = useState("");
  const [msg, setMsg] = useState("");

  const dec = Number(tokenDecimals ?? 18);
  const busy = isPending || isConfirming;

  const refetchAll = () => { refetchInfo(); refetchPending(); refetchStaked(); refetchBalance(); refetchAllowance(); };

  const needsApproval = (amtStr) => {
    if (!allowance || !amtStr) return false;
    try { return allowance < parseUnits(amtStr, dec); } catch { return false; }
  };

  const exec = async (fn) => {
    try {
      const tx = await fn();
      setHash(tx);
      setTimeout(refetchAll, 3000);
    } catch (e) {
      setMsg(`❌ ${e.shortMessage || e.message}`);
    }
  };

  const handleStake = () => exec(async () => {
    setMsg("Haciendo stake TIME...");
    const tx = await writeContractAsync({ address: CONTRACT_ADDRESS, abi: CONTRACT_ABI, functionName: "stakeTime", args: [parseUnits(stakeAmt, dec)] });
    setMsg("✅ Stake TIME exitoso");
    setStakeAmt("");
    return tx;
  });

  const handleUnstake = () => exec(async () => {
    setMsg("Retirando TIME...");
    const tx = await writeContractAsync({ address: CONTRACT_ADDRESS, abi: CONTRACT_ABI, functionName: "unstakeTime", args: [parseUnits(unstakeAmt, dec)] });
    setMsg("✅ Retiro TIME exitoso");
    setUnstakeAmt("");
    return tx;
  });

  const handleClaim = () => exec(async () => {
    setMsg("Reclamando WLD de staking TIME...");
    const dl = BigInt(Math.floor(Date.now() / 1000) + 600);
    const tx = await writeContractAsync({ address: CONTRACT_ADDRESS, abi: CONTRACT_ABI, functionName: "claimStakingRewards", args: [dl] });
    setMsg("✅ WLD reclamado");
    return tx;
  });

  if (!isConnected) {
    return <p className="staking-connect-hint">Conecta tu wallet para gestionar tu TIME stake.</p>;
  }

  return (
    <div className="staking-card">
      <div className="staking-card-header">
        <h3>TIME Staking</h3>
        <span className="staking-label time-label">Earn WLD</span>
      </div>

      {msg && (
        <div className={`staking-msg ${msg.startsWith("✅") ? "success" : msg.startsWith("❌") ? "error" : "info"}`}>
          {msg}
        </div>
      )}

      <div className="staking-stats">
        <div className="staking-stat">
          <span>TIME Stakeado (Bot)</span>
          <strong>{fmt(stakingInfo?.[0], dec)} {tokenSymbol ?? "TIME"}</strong>
        </div>
        <div className="staking-stat">
          <span>WLD Pendiente</span>
          <strong className="text-accent">{fmt(stakingInfo?.[1] ?? pendingReward, 18)}</strong>
        </div>
        <div className="staking-stat">
          <span>Total en Contrato</span>
          <strong>{fmt(stakingInfo?.[2], dec)}</strong>
        </div>
        <div className="staking-stat">
          <span>Tu Balance {tokenSymbol ?? "TIME"}</span>
          <strong>{fmt(tokenBalance, dec)}</strong>
        </div>
      </div>

      <div className="staking-actions">
        <div className="staking-section">
          <label>Depositar TIME</label>
          <div className="staking-input-row">
            <input type="number" min="0" placeholder={`Cantidad ${tokenSymbol ?? "TIME"}`} value={stakeAmt} onChange={e => setStakeAmt(e.target.value)} disabled={busy} />
            <button className="btn-sm btn-secondary" onClick={() => tokenBalance && setStakeAmt(fmt(tokenBalance, dec, 6))} disabled={!tokenBalance}>Max</button>
          </div>
          {stakeAmt && needsApproval(stakeAmt) ? (
            <ERC20ApproveBtn tokenAddress={timeToken} spender={CONTRACT_ADDRESS} onDone={refetchAllowance} />
          ) : (
            <button className="btn-primary staking-btn" onClick={handleStake} disabled={busy || !stakeAmt}>
              {busy ? "Procesando..." : "Depositar TIME"}
            </button>
          )}
        </div>

        <div className="staking-section">
          <label>Retirar TIME</label>
          <div className="staking-input-row">
            <input type="number" min="0" placeholder={`Cantidad ${tokenSymbol ?? "TIME"}`} value={unstakeAmt} onChange={e => setUnstakeAmt(e.target.value)} disabled={busy} />
            <button className="btn-sm btn-secondary" onClick={() => stakedBalance && setUnstakeAmt(fmt(stakedBalance, dec, 6))} disabled={!stakedBalance}>Max</button>
          </div>
          <button className="btn-warning staking-btn" onClick={handleUnstake} disabled={busy || !unstakeAmt}>
            {busy ? "Procesando..." : "Retirar TIME"}
          </button>
        </div>

        <div className="staking-section staking-claim">
          <div className="claim-info">
            <span>WLD pendiente de reclamar</span>
            <strong className="text-success">{fmt(stakingInfo?.[1] ?? pendingReward, 18)} WLD</strong>
          </div>
          <button className="btn-success staking-claim-btn" onClick={handleClaim} disabled={busy}>
            {busy ? "..." : "Reclamar WLD"}
          </button>
        </div>
      </div>

      <div className="staking-footer">
        <a href={`https://worldscan.org/address/${CONTRACT_ADDRESS}`} target="_blank" rel="noreferrer" className="staking-link">Ver bot ↗</a>
        {timeToken && <a href={`https://worldscan.org/token/${timeToken}`} target="_blank" rel="noreferrer" className="staking-link">Ver TIME ↗</a>}
      </div>
    </div>
  );
}

export default function StakingPanel() {
  const [activeTab, setActiveTab] = useState("acua");

  return (
    <div className="staking-panel">
      <div className="staking-panel-header">
        <h2>Staking Hub</h2>
        <div className="staking-tabs">
          <button className={`staking-tab ${activeTab === "acua" ? "active" : ""}`} onClick={() => setActiveTab("acua")}>
            ACUA Stake
          </button>
          <button className={`staking-tab ${activeTab === "time" ? "active" : ""}`} onClick={() => setActiveTab("time")}>
            TIME Stake
          </button>
        </div>
      </div>

      {activeTab === "acua" && <AcuaStakingCard />}
      {activeTab === "time" && <TimeStakingCard />}
    </div>
  );
}
