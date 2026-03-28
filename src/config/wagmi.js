import { createConfig, http } from "wagmi";
import { defineChain } from "viem";
import { walletConnect, injected, coinbaseWallet } from "wagmi/connectors";
import { createWeb3Modal } from "@web3modal/wagmi";

const WC_PROJECT_ID = "befde1d683c68f9cf789993998fbda38";

export const worldchain = defineChain({
  id: 480,
  name: "World Chain",
  nativeCurrency: { name: "Ether", symbol: "ETH", decimals: 18 },
  rpcUrls: {
    default: { http: ["https://worldchain-mainnet.g.alchemy.com/v2/bVo646pb8L7_W_nahCoqW"] },
  },
  blockExplorers: {
    default: { name: "Worldscan", url: "https://worldscan.org" },
  },
});

const metadata = {
  name: "Acua Company - AutoReinvest Bot",
  description: "Reinversión automática en Uniswap V3 con staking — World Chain",
  url: window?.location?.origin || "https://localhost",
  icons: [],
};

const connectors = [
  walletConnect({ projectId: WC_PROJECT_ID, metadata, showQrModal: false }),
  injected({ shimDisconnect: true }),
  coinbaseWallet({ appName: metadata.name }),
];

export const wagmiConfig = createConfig({
  chains: [worldchain],
  transports: {
    [worldchain.id]: http("https://worldchain-mainnet.g.alchemy.com/v2/bVo646pb8L7_W_nahCoqW"),
  },
  connectors,
});

createWeb3Modal({
  wagmiConfig,
  projectId: WC_PROJECT_ID,
  chains: [worldchain],
  defaultChain: worldchain,
  themeMode: "dark",
  themeVariables: {
    "--w3m-accent": "#0ea5e9",
    "--w3m-border-radius-master": "8px",
  },
});
