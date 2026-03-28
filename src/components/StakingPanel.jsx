import { useState } from "react";
import { useAccount, useReadContract, useWriteContract, useWaitForTransactionReceipt } from "wagmi";
import { formatUnits, parseUnits } from "viem";
import { ACUA_STAKING_ADDRESS, STAKING_ABI, ERC20_ABI } from "../config/staking.js";
import { SUSHI_TOKEN_ADDRESS, SUSHI_STAKING_ADDRESS, SUSHI_TOKEN_ABI, SUSHI_STAKING_ABI } from "../config/sushi.js";
import { TIME_TOKEN_ADDRESS, TIME_TOKEN_ABI, TIME_STAKING_ADDRESS, TIME_STAKING_ABI, WLD_TOKEN_ADDRESS } from "../config/time.js";
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

// ─── ACUA STAKING ────────────────────────────────────────────────────────────
function AcuaStakingCard() {
  const { address, isConnected } = useAccount();
  const userAddr = address ?? "0x0000000000000000000000000000000000000000";

  const { data: stakingToken } = useReadContract({ address: ACUA_STAKING_ADDRESS, abi: STAKING_ABI, functionName: "stakingToken", query: { staleTime: 60000 } });
  const { data: apr } = useReadContract({ address: ACUA_STAKING_ADDRESS, abi: STAKING_ABI, functionName: "apr", query: { refetchInterval: 60000 } });
  const { data: stakedBalance, refetch: refetchStaked } = useReadContract({ address: ACUA_STAKING_ADDRESS, abi: STAKING_ABI, functionName: "stakedBalance", args: [userAddr], query: { refetchInterval: 12000, enabled: !!address } });
  const { data: pendingRewards, refetch: refetchRewards } = useReadContract({ address: ACUA_STAKING_ADDRESS, abi: STAKING_ABI, functionName: "pendingRewards", args: [userAddr], query: { refetchInterval: 12000, enabled: !!address } });

  const minERC20 = [
    { inputs: [], name: "symbol", outputs: [{ type: "string" }], stateMutability: "view", type: "function" },
    { inputs: [{ name: "account", type: "address" }], name: "balanceOf", outputs: [{ type: "uint256" }], stateMutability: "view", type: "function" },
    { inputs: [], name: "decimals", outputs: [{ type: "uint8" }], stateMutability: "view", type: "function" },
    { inputs: [{ name: "owner", type: "address" }, { name: "spender", type: "address" }], name: "allowance", outputs: [{ type: "uint256" }], stateMutability: "view", type: "function" },
  ];

  const { data: tokenSymbol } = useReadContract({ address: stakingToken, abi: minERC20, functionName: "symbol", query: { enabled: !!stakingToken } });
  const { data: tokenBalance, refetch: refetchBalance } = useReadContract({ address: stakingToken, abi: minERC20, functionName: "balanceOf", args: [userAddr], query: { refetchInterval: 12000, enabled: !!stakingToken && !!address } });
  const { data: tokenDecimals } = useReadContract({ address: stakingToken, abi: minERC20, functionName: "decimals", query: { enabled: !!stakingToken } });
  const { data: allowance, refetch: refetchAllowance } = useReadContract({ address: stakingToken, abi: minERC20, functionName: "allowance", args: [userAddr, ACUA_STAKING_ADDRESS], query: { refetchInterval: 12000, enabled: !!stakingToken && !!address } });

  const { writeContractAsync, isPending } = useWriteContract();
  const [hash, setHash] = useState(null);
  const { isLoading: isConfirming } = useWaitForTransactionReceipt({ hash });
  const [stakeAmt, setStakeAmt]     = useState("");
  const [unstakeAmt, setUnstakeAmt] = useState("");
  const [msg, setMsg] = useState("");

  const dec  = Number(tokenDecimals ?? 18);
  const busy = isPending || isConfirming;
  const refetchAll = () => { refetchStaked(); refetchRewards(); refetchBalance(); refetchAllowance(); };

  const needsApproval = (amtStr) => {
    if (!allowance || !amtStr) return false;
    try { return allowance < parseUnits(amtStr, dec); } catch { return false; }
  };

  const exec = async (fn) => {
    try { const tx = await fn(); setHash(tx); setTimeout(refetchAll, 3000); }
    catch (e) { setMsg(`❌ ${e.shortMessage || e.message}`); }
  };

  if (!isConnected) return <p className="staking-connect-hint">Conecta tu wallet para gestionar tu ACUA stake.</p>;

  return (
    <div className="staking-card">
      <div className="staking-card-header">
        <h3>ACUA Staking</h3>
        <span className="staking-label">Earn APR</span>
      </div>
      {msg && <div className={`staking-msg ${msg.startsWith("✅") ? "success" : msg.startsWith("❌") ? "error" : "info"}`}>{msg}</div>}
      <div className="staking-stats">
        <div className="staking-stat"><span>APR</span><strong className="text-success">{apr ? (Number(apr) / 100).toFixed(2) : "—"}%</strong></div>
        <div className="staking-stat"><span>Tu Stake</span><strong>{fmt(stakedBalance, dec)} {tokenSymbol ?? "—"}</strong></div>
        <div className="staking-stat"><span>Recompensas</span><strong className="text-accent">{fmt(pendingRewards, dec)}</strong></div>
        <div className="staking-stat"><span>Balance Wallet</span><strong>{fmt(tokenBalance, dec)} {tokenSymbol ?? "—"}</strong></div>
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
            <button className="btn-primary staking-btn" onClick={() => exec(async () => { setMsg("Haciendo stake..."); const tx = await writeContractAsync({ address: ACUA_STAKING_ADDRESS, abi: STAKING_ABI, functionName: "stake", args: [parseUnits(stakeAmt, dec)] }); setMsg("✅ Stake exitoso"); setStakeAmt(""); return tx; })} disabled={busy || !stakeAmt}>
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
          <button className="btn-warning staking-btn" onClick={() => exec(async () => { setMsg("Retirando..."); const tx = await writeContractAsync({ address: ACUA_STAKING_ADDRESS, abi: STAKING_ABI, functionName: "unstake", args: [parseUnits(unstakeAmt, dec)] }); setMsg("✅ Retiro exitoso"); setUnstakeAmt(""); return tx; })} disabled={busy || !unstakeAmt}>
            {busy ? "Procesando..." : "Retirar"}
          </button>
        </div>
        <div className="staking-section staking-claim">
          <div className="claim-info">
            <span>Recompensas disponibles</span>
            <strong className="text-success">{fmt(pendingRewards, dec)} {tokenSymbol ?? ""}</strong>
          </div>
          <button className="btn-success staking-claim-btn" onClick={() => exec(async () => { setMsg("Reclamando..."); const tx = await writeContractAsync({ address: ACUA_STAKING_ADDRESS, abi: STAKING_ABI, functionName: "claim", args: [] }); setMsg("✅ Reclamado"); return tx; })} disabled={busy || !pendingRewards || pendingRewards === 0n}>
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

// ─── TIME STAKING (DIRECTO — no a través del bot) ────────────────────────────
function TimeStakingCard() {
  const { address, isConnected } = useAccount();
  const userAddr = address ?? "0x0000000000000000000000000000000000000000";

  const { data: stakedBalance, refetch: refetchStaked } = useReadContract({
    address: TIME_STAKING_ADDRESS, abi: TIME_STAKING_ABI,
    functionName: "stakedBalance", args: [userAddr],
    query: { refetchInterval: 12000, enabled: !!address },
  });
  const { data: pendingWLD, refetch: refetchPending } = useReadContract({
    address: TIME_STAKING_ADDRESS, abi: TIME_STAKING_ABI,
    functionName: "pendingWldReward", args: [userAddr],
    query: { refetchInterval: 12000, enabled: !!address },
  });
  const { data: totalStaked } = useReadContract({
    address: TIME_STAKING_ADDRESS, abi: TIME_STAKING_ABI,
    functionName: "totalStaked",
    query: { refetchInterval: 30000 },
  });

  const { data: timeBalance, refetch: refetchBalance } = useReadContract({
    address: TIME_TOKEN_ADDRESS, abi: TIME_TOKEN_ABI,
    functionName: "balanceOf", args: [userAddr],
    query: { refetchInterval: 12000, enabled: !!address },
  });
  const { data: allowance, refetch: refetchAllowance } = useReadContract({
    address: TIME_TOKEN_ADDRESS, abi: TIME_TOKEN_ABI,
    functionName: "allowance", args: [userAddr, TIME_STAKING_ADDRESS],
    query: { refetchInterval: 12000, enabled: !!address },
  });
  const { data: wldBalance, refetch: refetchWLD } = useReadContract({
    address: WLD_TOKEN_ADDRESS, abi: [{ inputs: [{ name: "account", type: "address" }], name: "balanceOf", outputs: [{ type: "uint256" }], stateMutability: "view", type: "function" }],
    functionName: "balanceOf", args: [userAddr],
    query: { refetchInterval: 12000, enabled: !!address },
  });

  const { writeContractAsync, isPending } = useWriteContract();
  const [hash, setHash] = useState(null);
  const { isLoading: isConfirming } = useWaitForTransactionReceipt({ hash });
  const [stakeAmt, setStakeAmt]     = useState("");
  const [unstakeAmt, setUnstakeAmt] = useState("");
  const [msg, setMsg] = useState("");

  const busy = isPending || isConfirming;
  const refetchAll = () => { refetchStaked(); refetchPending(); refetchBalance(); refetchAllowance(); refetchWLD(); };

  const needsApproval = (amtStr) => {
    if (!allowance || !amtStr) return false;
    try { return allowance < parseUnits(amtStr, 18); } catch { return false; }
  };

  const exec = async (fn) => {
    try { const tx = await fn(); setHash(tx); setTimeout(refetchAll, 3000); }
    catch (e) { setMsg(`❌ ${e.shortMessage || e.message}`); }
  };

  if (!isConnected) return <p className="staking-connect-hint">Conecta tu wallet para gestionar tu TIME stake.</p>;

  return (
    <div className="staking-card">
      <div className="staking-card-header">
        <h3>TIME Staking</h3>
        <span className="staking-label time-label">Earn WLD • Directo</span>
      </div>
      {msg && <div className={`staking-msg ${msg.startsWith("✅") ? "success" : msg.startsWith("❌") ? "error" : "info"}`}>{msg}</div>}
      <div className="staking-stats">
        <div className="staking-stat"><span>Tu TIME Stakeado</span><strong>{fmt(stakedBalance)} TIME</strong></div>
        <div className="staking-stat"><span>WLD Pendiente</span><strong className="text-accent">{fmt(pendingWLD)} WLD</strong></div>
        <div className="staking-stat"><span>Total Stakeado</span><strong>{fmt(totalStaked)} TIME</strong></div>
        <div className="staking-stat"><span>Tu Balance TIME</span><strong>{fmt(timeBalance)} TIME</strong></div>
        <div className="staking-stat"><span>Tu Balance WLD</span><strong>{fmt(wldBalance)} WLD</strong></div>
      </div>
      <div className="staking-actions">
        <div className="staking-section">
          <label>Depositar TIME</label>
          <div className="staking-input-row">
            <input type="number" min="0" placeholder="Cantidad TIME" value={stakeAmt} onChange={e => setStakeAmt(e.target.value)} disabled={busy} />
            <button className="btn-sm btn-secondary" onClick={() => timeBalance && setStakeAmt(fmt(timeBalance, 18, 6))} disabled={!timeBalance}>Max</button>
          </div>
          {stakeAmt && needsApproval(stakeAmt) ? (
            <ERC20ApproveBtn tokenAddress={TIME_TOKEN_ADDRESS} spender={TIME_STAKING_ADDRESS} label="Aprobar TIME" onDone={refetchAllowance} />
          ) : (
            <button className="btn-primary staking-btn" onClick={() => exec(async () => { setMsg("Stakeando TIME..."); const tx = await writeContractAsync({ address: TIME_STAKING_ADDRESS, abi: TIME_STAKING_ABI, functionName: "stake", args: [parseUnits(stakeAmt, 18)] }); setMsg("✅ Stake TIME exitoso"); setStakeAmt(""); return tx; })} disabled={busy || !stakeAmt}>
              {busy ? "Procesando..." : "Depositar TIME"}
            </button>
          )}
        </div>
        <div className="staking-section">
          <label>Retirar TIME</label>
          <div className="staking-input-row">
            <input type="number" min="0" placeholder="Cantidad TIME" value={unstakeAmt} onChange={e => setUnstakeAmt(e.target.value)} disabled={busy} />
            <button className="btn-sm btn-secondary" onClick={() => stakedBalance && setUnstakeAmt(fmt(stakedBalance, 18, 6))} disabled={!stakedBalance}>Max</button>
          </div>
          <button className="btn-warning staking-btn" onClick={() => exec(async () => { setMsg("Retirando TIME..."); const tx = await writeContractAsync({ address: TIME_STAKING_ADDRESS, abi: TIME_STAKING_ABI, functionName: "unstake", args: [parseUnits(unstakeAmt, 18)] }); setMsg("✅ TIME retirado"); setUnstakeAmt(""); return tx; })} disabled={busy || !unstakeAmt}>
            {busy ? "Procesando..." : "Retirar TIME"}
          </button>
        </div>
        <div className="staking-section staking-claim">
          <div className="claim-info">
            <span>WLD acumulado</span>
            <strong className="text-success">{fmt(pendingWLD)} WLD</strong>
          </div>
          <button className="btn-success staking-claim-btn" onClick={() => exec(async () => { setMsg("Reclamando WLD..."); const tx = await writeContractAsync({ address: TIME_STAKING_ADDRESS, abi: TIME_STAKING_ABI, functionName: "claimWldReward", args: [] }); setMsg("✅ WLD reclamado"); return tx; })} disabled={busy}>
            {busy ? "..." : "Reclamar WLD"}
          </button>
        </div>
      </div>
      <div className="staking-footer">
        <a href={`https://worldscan.org/address/${TIME_STAKING_ADDRESS}`} target="_blank" rel="noreferrer" className="staking-link">Ver contrato TIME ↗</a>
        <a href={`https://worldscan.org/token/${TIME_TOKEN_ADDRESS}`} target="_blank" rel="noreferrer" className="staking-link">Ver token TIME ↗</a>
      </div>
    </div>
  );
}

// ─── SUSHI STAKING ───────────────────────────────────────────────────────────
const MEMBERSHIP_NAMES = ["", "Plata", "Oro", "Platino", "Diamante"];

function SushiStakingCard() {
  const { address, isConnected } = useAccount();
  const userAddr = address ?? "0x0000000000000000000000000000000000000000";

  const { data: userInfo, refetch: refetchInfo } = useReadContract({
    address: SUSHI_STAKING_ADDRESS, abi: SUSHI_STAKING_ABI,
    functionName: "getUserInfo", args: [userAddr],
    query: { refetchInterval: 12000, enabled: !!address },
  });
  const { data: currentReward, refetch: refetchReward } = useReadContract({
    address: SUSHI_STAKING_ADDRESS, abi: SUSHI_STAKING_ABI,
    functionName: "currentReward", args: [userAddr],
    query: { refetchInterval: 12000, enabled: !!address },
  });
  const { data: sushiBalance, refetch: refetchBalance } = useReadContract({
    address: SUSHI_TOKEN_ADDRESS, abi: ERC20_ABI,
    functionName: "balanceOf", args: [userAddr],
    query: { refetchInterval: 12000, enabled: !!address },
  });
  const { data: allowance, refetch: refetchAllowance } = useReadContract({
    address: SUSHI_TOKEN_ADDRESS, abi: ERC20_ABI,
    functionName: "allowance", args: [userAddr, SUSHI_STAKING_ADDRESS],
    query: { refetchInterval: 12000, enabled: !!address },
  });

  const mem1 = useReadContract({ address: SUSHI_STAKING_ADDRESS, abi: SUSHI_STAKING_ABI, functionName: "MembershipTable", args: [1], query: { staleTime: 300000 } });
  const mem2 = useReadContract({ address: SUSHI_STAKING_ADDRESS, abi: SUSHI_STAKING_ABI, functionName: "MembershipTable", args: [2], query: { staleTime: 300000 } });
  const mem3 = useReadContract({ address: SUSHI_STAKING_ADDRESS, abi: SUSHI_STAKING_ABI, functionName: "MembershipTable", args: [3], query: { staleTime: 300000 } });
  const mem4 = useReadContract({ address: SUSHI_STAKING_ADDRESS, abi: SUSHI_STAKING_ABI, functionName: "MembershipTable", args: [4], query: { staleTime: 300000 } });
  const memberships = [mem1.data, mem2.data, mem3.data, mem4.data];

  const { writeContractAsync, isPending } = useWriteContract();
  const [hash, setHash] = useState(null);
  const { isLoading: isConfirming } = useWaitForTransactionReceipt({ hash });
  const [selectedMem, setSelectedMem] = useState(1);
  const [withdrawAmt, setWithdrawAmt] = useState("");
  const [msg, setMsg] = useState("");

  const busy = isPending || isConfirming;
  const refetchAll = () => { refetchInfo(); refetchReward(); refetchBalance(); refetchAllowance(); };

  const selectedMemData = memberships[selectedMem - 1];
  const cost = selectedMemData?.cost ?? 0n;
  const needsApproval = allowance !== undefined && cost > 0n && allowance < cost;

  const exec = async (fn) => {
    try { const tx = await fn(); setHash(tx); setTimeout(refetchAll, 3000); }
    catch (e) { setMsg(`❌ ${e.shortMessage || e.message}`); }
  };

  if (!isConnected) return <p className="staking-connect-hint">Conecta tu wallet para gestionar tu SUSHI stake.</p>;

  const currentMem  = userInfo ? Number(userInfo.membership ?? userInfo[5] ?? 0) : 0;
  const stakedBal   = userInfo?.balance ?? userInfo?.[1] ?? 0n;
  const intereses   = userInfo?.intereses ?? userInfo?.[0] ?? 0n;

  return (
    <div className="staking-card sushi-card">
      <div className="staking-card-header">
        <h3>SUSHI Staking</h3>
        <span className="staking-label sushi-label">Membership Vault</span>
      </div>
      {msg && <div className={`staking-msg ${msg.startsWith("✅") ? "success" : msg.startsWith("❌") ? "error" : "info"}`}>{msg}</div>}

      <div className="staking-stats">
        <div className="staking-stat"><span>Membership Actual</span><strong className="text-accent">{currentMem > 0 ? MEMBERSHIP_NAMES[currentMem] ?? `#${currentMem}` : "Sin membresía"}</strong></div>
        <div className="staking-stat"><span>Balance Stakeado</span><strong>{fmt(stakedBal)} SUSHI</strong></div>
        <div className="staking-stat"><span>Intereses Acum.</span><strong className="text-success">{fmt(intereses)} SUSHI</strong></div>
        <div className="staking-stat"><span>Reward Actual</span><strong className="text-accent">{fmt(currentReward)} SUSHI</strong></div>
        <div className="staking-stat"><span>Tu Balance SUSHI</span><strong>{fmt(sushiBalance)} SUSHI</strong></div>
      </div>

      <div className="staking-actions">
        <div className="staking-section">
          <label>Comprar / Actualizar Membresía</label>
          <div className="membership-grid">
            {memberships.map((m, i) => {
              const id = i + 1;
              return (
                <button
                  key={id}
                  className={`mem-btn ${selectedMem === id ? "active" : ""}`}
                  onClick={() => setSelectedMem(id)}
                >
                  <span className="mem-name">{MEMBERSHIP_NAMES[id]}</span>
                  {m && <span className="mem-apy">{Number(m[0])}% APY</span>}
                  {m && <span className="mem-cost">{fmt(m[1])} SUSHI</span>}
                </button>
              );
            })}
          </div>
          {selectedMemData && (
            <div className="mem-details">
              Costo: <strong>{fmt(cost)} SUSHI</strong> | APY: <strong>{Number(selectedMemData[0])}%</strong>
            </div>
          )}
          {needsApproval ? (
            <ERC20ApproveBtn tokenAddress={SUSHI_TOKEN_ADDRESS} spender={SUSHI_STAKING_ADDRESS} label="Aprobar SUSHI" onDone={refetchAllowance} />
          ) : (
            <button
              className="btn-primary staking-btn"
              onClick={() => exec(async () => {
                setMsg(`Comprando membresía ${MEMBERSHIP_NAMES[selectedMem]}...`);
                const tx = await writeContractAsync({
                  address: SUSHI_STAKING_ADDRESS, abi: SUSHI_STAKING_ABI,
                  functionName: "buyMembership", args: [cost, selectedMem],
                });
                setMsg(`✅ Membresía ${MEMBERSHIP_NAMES[selectedMem]} activada`);
                return tx;
              })}
              disabled={busy || !selectedMemData}
            >
              {busy ? "Procesando..." : `Activar ${MEMBERSHIP_NAMES[selectedMem] ?? "Membresía"}`}
            </button>
          )}
        </div>

        <div className="staking-section staking-claim">
          <div className="claim-info">
            <span>Intereses acumulados</span>
            <strong className="text-success">{fmt(intereses)} SUSHI</strong>
          </div>
          <button
            className="btn-success staking-claim-btn"
            onClick={() => exec(async () => {
              setMsg("Retirando intereses...");
              const tx = await writeContractAsync({
                address: SUSHI_STAKING_ADDRESS, abi: SUSHI_STAKING_ABI,
                functionName: "retirarIntereses", args: [],
              });
              setMsg("✅ Intereses retirados");
              return tx;
            })}
            disabled={busy || !intereses || intereses === 0n}
          >
            {busy ? "..." : "Retirar Intereses"}
          </button>
        </div>

        <div className="staking-section">
          <label>Retirar Balance Stakeado</label>
          <div className="staking-input-row">
            <input
              type="number" min="0" placeholder="Cantidad SUSHI"
              value={withdrawAmt} onChange={e => setWithdrawAmt(e.target.value)} disabled={busy}
            />
            <button className="btn-sm btn-secondary" onClick={() => stakedBal && setWithdrawAmt(fmt(stakedBal, 18, 6))} disabled={!stakedBal}>Max</button>
          </div>
          <button
            className="btn-warning staking-btn"
            onClick={() => exec(async () => {
              setMsg("Retirando balance...");
              const tx = await writeContractAsync({
                address: SUSHI_STAKING_ADDRESS, abi: SUSHI_STAKING_ABI,
                functionName: "retirarBalance", args: [parseUnits(withdrawAmt, 18)],
              });
              setMsg("✅ Balance retirado");
              setWithdrawAmt("");
              return tx;
            })}
            disabled={busy || !withdrawAmt}
          >
            {busy ? "Procesando..." : "Retirar SUSHI"}
          </button>
        </div>
      </div>

      <div className="staking-footer">
        <a href={`https://worldscan.org/address/${SUSHI_STAKING_ADDRESS}`} target="_blank" rel="noreferrer" className="staking-link">Ver contrato SUSHI ↗</a>
        <a href={`https://worldscan.org/token/${SUSHI_TOKEN_ADDRESS}`} target="_blank" rel="noreferrer" className="staking-link">Ver token SUSHI ↗</a>
      </div>
    </div>
  );
}

// ─── PANEL PRINCIPAL ─────────────────────────────────────────────────────────
export default function StakingPanel() {
  const [activeTab, setActiveTab] = useState("acua");

  return (
    <div className="staking-panel">
      <div className="staking-panel-header">
        <h2>Staking Hub</h2>
        <div className="staking-tabs">
          <button className={`staking-tab ${activeTab === "acua" ? "active" : ""}`} onClick={() => setActiveTab("acua")}>
            ACUA
          </button>
          <button className={`staking-tab ${activeTab === "time" ? "active" : ""}`} onClick={() => setActiveTab("time")}>
            TIME
          </button>
          <button className={`staking-tab ${activeTab === "sushi" ? "active" : ""}`} onClick={() => setActiveTab("sushi")}>
            SUSHI
          </button>
        </div>
      </div>

      {activeTab === "acua"  && <AcuaStakingCard />}
      {activeTab === "time"  && <TimeStakingCard />}
      {activeTab === "sushi" && <SushiStakingCard />}
    </div>
  );
}
