"use client";

import { useMemo } from "react";
import { useAccount, useReadContract } from "wagmi";
import { formatUnits } from "viem";
import {
  TrendingUp,
  Wallet,
  Activity,
  ArrowUpRight,
  ArrowDownLeft,
} from "lucide-react";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  SAFE_VAULT_ADDRESS,
  SAFE_VAULT_ABI,
  EURC_DECIMALS,
} from "@/lib/contracts/safeVault";

const CSAFE_DECIMALS = 15;

// Mock vault configs - adjust these to match your actual vaults
const VAULT_CONFIGS = [
  {
    name: "Safe Vault",
    symbol: "cSAFE",
    address: SAFE_VAULT_ADDRESS,
    abi: SAFE_VAULT_ABI,
    underlying: "EURC",
    apy: "4.0",
  },
  // Add more vaults here as needed
  // {
  //   name: "Balanced Vault",
  //   symbol: "cBLNC",
  //   address: "0x...",
  //   abi: BLNC_VAULT_ABI,
  //   underlying: "USDC",
  //   apy: "5.5",
  // },
  // {
  //   name: "Dynamic Vault",
  //   symbol: "cDNMC",
  //   address: "0x...",
  //   abi: DNMC_VAULT_ABI,
  //   underlying: "USDT",
  //   apy: "6.2",
  // },
];

interface VaultPosition {
  name: string;
  symbol: string;
  balance: number;
  underlying: string;
  underlyingBalance: number;
  apy: string;
  dailyYield: number;
  totalYield: number;
}

export default function Dashboard() {
  const { address } = useAccount();

  // Fetch Safe Vault position
  const { data: csafeBalanceRaw } = useReadContract({
    address: SAFE_VAULT_ADDRESS,
    abi: SAFE_VAULT_ABI,
    functionName: "balanceOf",
    args: address ? [address] : undefined,
    query: { enabled: !!address },
  });

  const { data: totalAssetsRaw } = useReadContract({
    address: SAFE_VAULT_ADDRESS,
    abi: SAFE_VAULT_ABI,
    functionName: "totalAssets",
  });

  const { data: totalSupplyRaw } = useReadContract({
    address: SAFE_VAULT_ADDRESS,
    abi: SAFE_VAULT_ABI,
    functionName: "totalSupply",
  });

  const { data: pricePerShareRaw } = useReadContract({
    address: SAFE_VAULT_ADDRESS,
    abi: SAFE_VAULT_ABI,
    functionName: "convertToAssets",
    args: [BigInt(10 ** CSAFE_DECIMALS)],
  });

  // Calculate positions
  const positions = useMemo(() => {
    const vaultPositions: VaultPosition[] = [];

    // Safe Vault position
    if (csafeBalanceRaw && pricePerShareRaw) {
      const csafeBalance = Number(
        formatUnits(csafeBalanceRaw as bigint, CSAFE_DECIMALS),
      );
      const pricePerShare = Number(
        formatUnits(pricePerShareRaw as bigint, EURC_DECIMALS),
      );
      const underlyingBalance = csafeBalance * pricePerShare;

      // Estimate daily yield (APY / 365)
      const dailyYield = (underlyingBalance * 4.0) / 36500;

      vaultPositions.push({
        name: "Safe Vault",
        symbol: "cSAFE",
        balance: csafeBalance,
        underlying: "EURC",
        underlyingBalance,
        apy: "4.0%",
        dailyYield,
        totalYield: dailyYield * 30, // 30-day estimate
      });
    }

    return vaultPositions;
  }, [csafeBalanceRaw, pricePerShareRaw]);

  const totalPortfolioValue = useMemo(() => {
    return positions.reduce((sum, pos) => sum + pos.underlyingBalance, 0);
  }, [positions]);

  const totalDailyYield = useMemo(() => {
    return positions.reduce((sum, pos) => sum + pos.dailyYield, 0);
  }, [positions]);

  const totalMonthlyYield = useMemo(() => {
    return positions.reduce((sum, pos) => sum + pos.totalYield, 0);
  }, [positions]);

  if (!address) {
    return (
      <div className="min-h-screen w-3/4 mx-auto mt-14">
        <div className="flex items-center justify-center h-96">
          <Card className="w-full max-w-md">
            <CardHeader className="text-center">
              <CardTitle>Connect Your Wallet</CardTitle>
              <CardDescription>
                Please connect your wallet to view your positions
              </CardDescription>
            </CardHeader>
          </Card>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen w-3/4 mx-auto mt-14 pb-10">
      {/* Header */}
      <div className="space-y-2 mb-8">
        <h1 className="text-4xl font-bold">Your Dashboard</h1>
        <p className="text-muted-foreground">
          Manage and monitor all your vault positions
        </p>
      </div>

      {/* Portfolio Summary Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-8">
        {/* Total Portfolio Value */}
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">
              Portfolio Value
            </CardTitle>
            <Wallet className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              ${totalPortfolioValue.toFixed(2)}
            </div>
            <p className="text-xs text-muted-foreground mt-1">
              Across all vaults
            </p>
          </CardContent>
        </Card>

        {/* Daily Yield */}
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Daily Yield</CardTitle>
            <TrendingUp className="h-4 w-4 text-green-600" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              ${totalDailyYield.toFixed(4)}
            </div>
            <p className="text-xs text-muted-foreground mt-1">
              ~${totalMonthlyYield.toFixed(2)}/month
            </p>
          </CardContent>
        </Card>

        {/* Active Positions */}
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">
              Active Positions
            </CardTitle>
            <Activity className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {positions.filter((p) => p.balance > 0).length}
            </div>
            <p className="text-xs text-muted-foreground mt-1">
              {positions.length} total vaults
            </p>
          </CardContent>
        </Card>
      </div>

      {/* Positions Table */}
      <Card>
        <CardHeader>
          <CardTitle>Your Positions</CardTitle>
          <CardDescription>
            Detailed view of your vault positions and yields
          </CardDescription>
        </CardHeader>
        <CardContent>
          {positions.length === 0 ? (
            <div className="text-center py-8">
              <p className="text-muted-foreground mb-4">
                No active positions yet
              </p>
              <p className="text-sm text-muted-foreground">
                Start by depositing into a vault to see your positions here
              </p>
            </div>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Vault</TableHead>
                  <TableHead className="text-right">Balance</TableHead>
                  <TableHead className="text-right">
                    Underlying Value
                  </TableHead>
                  <TableHead className="text-right">APY</TableHead>
                  <TableHead className="text-right">Daily Yield</TableHead>
                  <TableHead className="text-right">30-Day Yield</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {positions.map((position) => (
                  <TableRow key={position.symbol}>
                    <TableCell>
                      <div className="flex items-center gap-2">
                        <div className="w-8 h-8 rounded-full bg-gradient-to-br from-blue-400 to-blue-600 flex items-center justify-center text-xs text-white font-bold">
                          {position.symbol.substring(1, 2)}
                        </div>
                        <div>
                          <p className="font-medium">{position.name}</p>
                          <p className="text-xs text-muted-foreground">
                            {position.symbol}
                          </p>
                        </div>
                      </div>
                    </TableCell>
                    <TableCell className="text-right">
                      <div className="font-medium">
                        {position.balance.toFixed(6)}
                      </div>
                      <p className="text-xs text-muted-foreground">
                        {position.symbol}
                      </p>
                    </TableCell>
                    <TableCell className="text-right">
                      <div className="font-medium">
                        ${position.underlyingBalance.toFixed(2)}
                      </div>
                      <p className="text-xs text-muted-foreground">
                        {position.underlying}
                      </p>
                    </TableCell>
                    <TableCell className="text-right">
                      <Badge variant="secondary">{position.apy}</Badge>
                    </TableCell>
                    <TableCell className="text-right">
                      <div className="flex items-center justify-end gap-1 font-medium text-green-600">
                        <ArrowUpRight className="h-4 w-4" />
                        ${position.dailyYield.toFixed(4)}
                      </div>
                    </TableCell>
                    <TableCell className="text-right">
                      <div className="flex items-center justify-end gap-1 font-medium text-green-600">
                        <ArrowUpRight className="h-4 w-4" />
                        ${position.totalYield.toFixed(2)}
                      </div>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>

      {/* Recent Activity */}
      <Card className="mt-8">
        <CardHeader>
          <CardTitle>Recent Activity</CardTitle>
          <CardDescription>Your latest transactions and events</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            {/* Sample activity items - in production, fetch from contract events/subgraph */}
            <div className="flex items-center justify-between py-3 border-b">
              <div className="flex items-center gap-3">
                <div className="w-8 h-8 rounded-full bg-green-100 dark:bg-green-900 flex items-center justify-center">
                  <ArrowDownLeft className="h-4 w-4 text-green-600" />
                </div>
                <div>
                  <p className="font-medium text-sm">Deposited to Safe Vault</p>
                  <p className="text-xs text-muted-foreground">2 hours ago</p>
                </div>
              </div>
              <span className="text-sm font-medium text-green-600">
                +1,000 EURC
              </span>
            </div>

            <div className="flex items-center justify-between py-3 border-b">
              <div className="flex items-center gap-3">
                <div className="w-8 h-8 rounded-full bg-blue-100 dark:bg-blue-900 flex items-center justify-center">
                  <TrendingUp className="h-4 w-4 text-blue-600" />
                </div>
                <div>
                  <p className="font-medium text-sm">Yield Generated</p>
                  <p className="text-xs text-muted-foreground">1 day ago</p>
                </div>
              </div>
              <span className="text-sm font-medium text-blue-600">
                +0.11 EURC
              </span>
            </div>

            <div className="flex items-center justify-between py-3">
              <div className="flex items-center gap-3">
                <div className="w-8 h-8 rounded-full bg-purple-100 dark:bg-purple-900 flex items-center justify-center">
                  <ArrowUpRight className="h-4 w-4 text-purple-600" />
                </div>
                <div>
                  <p className="font-medium text-sm">Withdrawn from Safe Vault</p>
                  <p className="text-xs text-muted-foreground">3 days ago</p>
                </div>
              </div>
              <span className="text-sm font-medium text-purple-600">
                -500 EURC
              </span>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
