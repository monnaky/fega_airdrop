import { Toaster } from "@/components/ui/toaster";
import { Toaster as Sonner } from "@/components/ui/sonner";
import { TooltipProvider } from "@/components/ui/tooltip";
import { BrowserRouter, Routes, Route } from "react-router-dom";
import { ThirdwebProvider } from "@thirdweb-dev/react";
import { WalletProvider } from "@/contexts/WalletContext";

import Index from "./pages/Index";
import NewAdmin from "./pages/NewAdmin";
import NotFound from "./pages/NotFound";
import NewWalletDashboard from "./pages/NewWalletDashboard";
import AdminSettings from "./components/AdminSettings";

const App = () => (
  <ThirdwebProvider
    activeChain="binance"
    supportedChains={[
      {
        chainId: 56,
        rpc: ["https://bsc-dataseed.binance.org/"],
        nativeCurrency: {
          decimals: 18,
          name: "Binance Coin",
          symbol: "BNB",
        },
        shortName: "bnb",
        slug: "binance",
        testnet: false,
        chain: "BSC",
        name: "Binance Smart Chain Mainnet",
      },
    ]}
  >
    <WalletProvider>
      <TooltipProvider>
        <Toaster />
        <Sonner />
        <BrowserRouter>
          <Routes>
            <Route path="/" element={<Index />} />
            <Route path="/dashboard" element={<NewWalletDashboard />} />
            <Route path="/admin" element={<NewAdmin />} />
            <Route path="/admin/settings" element={<AdminSettings />} />
            {/* ADD ALL CUSTOM ROUTES ABOVE THE CATCH-ALL "*" ROUTE */}
            <Route path="*" element={<NotFound />} />
          </Routes>
        </BrowserRouter>
      </TooltipProvider>
    </WalletProvider>
  </ThirdwebProvider>
);

export default App;
