import { useState } from "react";
import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import { useAccount } from "wagmi";
import Header from "./components/Header.jsx";
import Dashboard from "./pages/Dashboard.jsx";
import OwnerPanel from "./pages/OwnerPanel.jsx";
import "./styles/App.css";

export default function App() {
  const { address } = useAccount();

  return (
    <BrowserRouter future={{ v7_startTransition: true, v7_relativeSplatPath: true }}>
      <div className="app">
        <Header />
        <main className="main-content">
          <Routes>
            <Route path="/" element={<Dashboard />} />
            <Route path="/owner" element={<OwnerPanel />} />
            <Route path="*" element={<Navigate to="/" />} />
          </Routes>
        </main>
      </div>
    </BrowserRouter>
  );
}
