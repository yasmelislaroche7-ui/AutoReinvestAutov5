import { Link, useLocation } from "react-router-dom";
import { useAccount } from "wagmi";
import { useIsOwner } from "../hooks/useContract.js";
import "../styles/Header.css";

export default function Header() {
  const { isConnected } = useAccount();
  const isOwner = useIsOwner();
  const location = useLocation();

  return (
    <header className="header">
      <div className="header-left">
        <div className="logo">
          <span className="logo-icon">💧</span>
          <span className="logo-text">Acua Company</span>
          <span className="logo-sub">AutoReinvest</span>
        </div>
        <nav className="nav">
          <Link className={`nav-link ${location.pathname === "/" ? "active" : ""}`} to="/">
            Dashboard
          </Link>
          <Link className={`nav-link ${location.pathname === "/staking" ? "active" : ""}`} to="/staking">
            Staking
          </Link>
          {isConnected && isOwner && (
            <Link className={`nav-link ${location.pathname === "/owner" ? "active" : ""}`} to="/owner">
              Panel Owner
            </Link>
          )}
        </nav>
      </div>
      <div className="header-right">
        <w3m-button />
      </div>
    </header>
  );
}
