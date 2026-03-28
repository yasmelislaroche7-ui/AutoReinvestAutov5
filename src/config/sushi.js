// =======================================================
// SUSHI CONTRACTS (TOKEN + STAKING)
// =======================================================

// 🍣 Sushi Token (faucet + burn)
export const SUSHI_TOKEN_ADDRESS = "0xab09A728E53d3d6BC438BE95eeD46Da0Bbe7FB38";

// 🍣 Sushi Staking / Membership Vault
export const SUSHI_STAKING_ADDRESS = "0x500EC550891D8f03DdD32d5854A3B15d052299Ca";


// =======================================================
// SUSHI TOKEN ABI
// =======================================================

export const SUSHI_TOKEN_ABI = [
  "function claim() external",
  "function burn(uint256 amount) external",

  "function balanceOf(address account) external view returns(uint256)",
  "function decimals() external view returns(uint8)",
  "function name() external view returns(string)",
  "function symbol() external view returns(string)",
  "function totalSupply() external view returns(uint256)",

  "function nonces(address owner) external view returns(uint256)",
  "function viewBlocksUntilClaim(address user) external view returns(uint256)"
];


// =======================================================
// SUSHI STAKING ABI (VAULT + MEMBERSHIPS)
// =======================================================

export const SUSHI_STAKING_ABI = [

  // 🪪 Comprar Membership
  "function buyMembership(uint256 amount,uint8 membership_id) external",

  // 💰 Retirar intereses generados
  "function retirarIntereses() external",

  // 🏦 Retirar balance stakeado
  "function retirarBalance(uint256 amount) external",

  // 📊 Ver recompensa acumulada
  "function currentReward(address user) external view returns(uint256)",

  // 👤 Info completa del usuario
  "function getUserInfo(address user) external view returns(tuple(uint256 intereses,uint256 balance,uint256 startBlock,uint256 lastClaimIntereses,uint256 lastClaimBalance,uint8 membership))",

  // 📋 Tabla de memberships
  "function MembershipTable(uint8 id) external view returns(uint16 APY,uint256 cost,uint256 APY_Block,uint256 cantidad)"
];