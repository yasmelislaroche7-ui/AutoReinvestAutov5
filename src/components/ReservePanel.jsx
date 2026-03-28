import { useState } from "react";
import { formatEther } from "viem";
import { useAccount } from "wagmi";
import { useContractRead, useContractWrite } from "../hooks/useContract.js";
import "../styles/ReservePanel.css";

const TOKENS = {
  WLD: { label: "WLD", fn: "WLD" },
  H2O: { label: "H2O", fn: "H2O" },
  BTCH2O: { label: "BTCH2O", fn: "BTCH2O" },
};

export default function ReservePanel() {
  const { address } = useAccount();
  const { data: reserves, refetch } = useContractRead("getReserves", [], true);
  const { data: wldAddr } = useContractRead("WLD");
  const { data: h2oAddr } = useContractRead("H2O");
  const { data: btch2oAddr } = useContractRead("BTCH2O");
  const { write, isPending } = useContractWrite();

  const [withdrawToken, setWithdrawToken] = useState("WLD");
  const [withdrawAmt, setWithdrawAmt] = useState("");
  const [withdrawTo, setWithdrawTo] = useState("");
  const [msg, setMsg] = useState("");

  const tokenAddrs = { WLD: wldAddr, H2O: h2oAddr, BTCH2O: btch2oAddr };

  const handleWithdraw = async () => {
    if (!withdrawAmt || !withdrawTo) return;
    const tokenAddr = tokenAddrs[withdrawToken];
    if (!tokenAddr) return;
    try {
      setMsg("Enviando retiro...");
      const amt = BigInt(Math.floor(parseFloat(withdrawAmt) * 1e18));
      await write("withdrawReserve", [tokenAddr, amt, withdrawTo]);
      setMsg("✅ Retiro completado");
      setWithdrawAmt("");
      refetch();
    } catch (e) {
      setMsg(`❌ Error: ${e.shortMessage || e.message}`);
    }
  };

  const handleWithdrawAll = async (tokenKey) => {
    const tokenAddr = tokenAddrs[tokenKey];
    if (!tokenAddr) return;
    try {
      setMsg(`Retirando todo ${tokenKey}...`);
      await write("withdrawAll", [tokenAddr, address]);
      setMsg("✅ Todo retirado");
      refetch();
    } catch (e) {
      setMsg(`❌ Error: ${e.shortMessage || e.message}`);
    }
  };

  return (
    <div className="reserve-panel">
      <h3>Reservas del Contrato</h3>
      {msg && <div className="reserve-msg">{msg}</div>}

      <div className="reserves-grid">
        {reserves && (
          <>
            <div className="reserve-item">
              <span className="reserve-token">WLD</span>
              <span className="reserve-amount">{parseFloat(formatEther(reserves[0])).toFixed(6)}</span>
              <button className="btn-secondary btn-xs" onClick={() => handleWithdrawAll("WLD")} disabled={isPending}>
                Retirar todo
              </button>
            </div>
            <div className="reserve-item">
              <span className="reserve-token">H2O</span>
              <span className="reserve-amount">{parseFloat(formatEther(reserves[1])).toFixed(6)}</span>
              <button className="btn-secondary btn-xs" onClick={() => handleWithdrawAll("H2O")} disabled={isPending}>
                Retirar todo
              </button>
            </div>
            <div className="reserve-item">
              <span className="reserve-token">BTCH2O</span>
              <span className="reserve-amount">{parseFloat(formatEther(reserves[2])).toFixed(6)}</span>
              <button className="btn-secondary btn-xs" onClick={() => handleWithdrawAll("BTCH2O")} disabled={isPending}>
                Retirar todo
              </button>
            </div>
          </>
        )}
      </div>

      <div className="withdraw-form">
        <h4>Retiro Manual</h4>
        <div className="form-row">
          <select value={withdrawToken} onChange={e => setWithdrawToken(e.target.value)}>
            <option value="WLD">WLD</option>
            <option value="H2O">H2O</option>
            <option value="BTCH2O">BTCH2O</option>
          </select>
          <input type="number" placeholder="Cantidad" value={withdrawAmt} onChange={e => setWithdrawAmt(e.target.value)} />
        </div>
        <div className="form-row">
          <input type="text" placeholder="Dirección destino" value={withdrawTo} onChange={e => setWithdrawTo(e.target.value)} />
          <button className="btn-primary" onClick={handleWithdraw} disabled={isPending || !withdrawAmt || !withdrawTo}>
            {isPending ? "Enviando..." : "Retirar"}
          </button>
        </div>
      </div>
    </div>
  );
}
