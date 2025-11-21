"use client";

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Shield, TrendingUp, DollarSign, Activity } from "lucide-react";
import VaultComposition from "@/components/vault/VaultComposition";
import VaultActivity from "@/components/vault/VaultActivity";
import VaultCharts from "@/components/vault/VaultCharts";
import VaultStats from "@/components/vault/VaultStats";

export default function SafeVaultPage() {
  const vaultData = {
    name: "Safe Vault",
    apy: "4.2%",
    tvl: "$2,547,832",
    pricePerShare: "$1.042",
    risk: "Low",
    description: "Conservative yield strategy focused on stablecoin lending with minimal risk exposure",
  };

  const composition = [
    { protocol: "Aave EURC Lending", allocation: 32.7, amount: "$833,141" },
    { protocol: "Aave Umbrella", allocation: 18.4, amount: "$468,801" },
    { protocol: "yoEUR", allocation: 15.6, amount: "$397,462" },
    { protocol: "Morpho USDC", allocation: 9.2, amount: "$234,400" },
    { protocol: "USDe Ethena", allocation: 9.2, amount: "$234,400" },
    { protocol: "Fiat Reserve", allocation: 8.0, amount: "$203,827" },
    { protocol: "WBTC", allocation: 6.9, amount: "$175,800" },
  ];

  return (
    <div className="min-h-screen w-full px-4 py-8">
      <div className="max-w-7xl mx-auto space-y-6">
        <div className="flex items-start justify-between">
          <div className="space-y-2">
            <div className="flex items-center gap-3">
              <Shield className="h-10 w-10 text-blue-500" />
              <div>
                <h1 className="text-4xl font-bold">{vaultData.name}</h1>
                <p className="text-muted-foreground">{vaultData.description}</p>
              </div>
            </div>
          </div>
          <div className="flex gap-3">
            <Button variant="outline" size="lg">
              Withdraw
            </Button>
            <Button size="lg">Deposit</Button>
          </div>
        </div>

        <VaultStats vaultData={vaultData} />

        <Tabs defaultValue="overview" className="space-y-6">
          <TabsList className="grid w-full grid-cols-3 lg:w-[400px]">
            <TabsTrigger value="overview">Overview</TabsTrigger>
            <TabsTrigger value="composition">Composition</TabsTrigger>
            <TabsTrigger value="activity">Activity</TabsTrigger>
          </TabsList>

          <TabsContent value="overview" className="space-y-6">
            <VaultCharts />
          </TabsContent>

          <TabsContent value="composition">
            <VaultComposition composition={composition} totalTVL={vaultData.tvl} />
          </TabsContent>

          <TabsContent value="activity">
            <VaultActivity />
          </TabsContent>
        </Tabs>
      </div>
    </div>
  );
}
