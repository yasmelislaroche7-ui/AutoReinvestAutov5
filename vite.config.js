import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [react()],
  server: {
    port: 5000,
    host: true,
    allowedHosts: true,
  },
  define: {
    global: "globalThis",
  },
  build: {
    sourcemap: false,
  },
  optimizeDeps: {
    exclude: ["@reown/appkit"],
    esbuildOptions: {
      sourcemap: false,
      ignoreAnnotations: true,
    },
  },
});
