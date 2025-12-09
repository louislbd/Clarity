"use client";

import { useMemo, useState } from "react";
import {
  useAccount,
  useReadContract,
  useWriteContract,
  useWaitForTransactionReceipt,
} from "wagmi";
import { formatUnits, parseUnits } from "viem";
import { Shield } from "lucide-react";
import { Button } from "@/components/ui/button";
import VaultComposition from "@/components/vault/VaultComposition";
import VaultActivity from "@/components/vault/VaultActivity";
import VaultCharts from "@/components/vault/VaultCharts";
import VaultStats from "@/components/vault/VaultStats";
import {
  SAFE_VAULT_ADDRESS,
  SAFE_VAULT_ABI,
  SAFE_VAULT_DECIMALS,
} from "@/lib/contracts/safeVault";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";

// MockUSDC deployed address
const MOCK_EURC_ADDRESS = "0x08878E4722049586b02E2A8D2646C7E3164c6301";

// ERC20 approve ABI fragment
const ERC20_ABI = [
  {
    type: "function",
    name: "approve",
    stateMutability: "nonpayable",
    inputs: [
      { name: "spender", type: "address" },
      { name: "amount", type: "uint256" },
    ],
    outputs: [{ name: "", type: "bool" }],
  },
] as const;

export default function SafeVaultPage() {
  const { address } = useAccount();
  const [amount, setAmount] = useState("");

  // --- READS ---

  const { data: totalAssets } = useReadContract({
    address: SAFE_VAULT_ADDRESS,
    abi: SAFE_VAULT_ABI,
    functionName: "totalAssets",
  });

  const { data: pricePerShareRaw } = useReadContract({
    address: SAFE_VAULT_ADDRESS,
    abi: SAFE_VAULT_ABI,
    functionName: "convertToAssets",
    args: [BigInt(10 ** SAFE_VAULT_DECIMALS)],
  });

  const { data: apyRaw } = useReadContract({
    address: SAFE_VAULT_ADDRESS,
    abi: SAFE_VAULT_ABI,
    functionName: "getAPY",
  });

  const { data: allocationsRaw } = useReadContract({
    address: SAFE_VAULT_ADDRESS,
    abi: SAFE_VAULT_ABI,
    functionName: "getAllocations",
  });

  const vaultData = useMemo(() => {
    const tvl =
      totalAssets != null
        ? `$${Number(
            formatUnits(totalAssets as bigint, SAFE_VAULT_DECIMALS),
          ).toLocaleString()}`
        : "…";

    const pps =
      pricePerShareRaw != null
        ? `$${Number(
            formatUnits(pricePerShareRaw as bigint, SAFE_VAULT_DECIMALS),
          ).toFixed(3)}`
        : "…";

    const apy = apyRaw != null ? `${Number(apyRaw as bigint) / 100}%` : "…";

    return {
      name: "Safe Vault",
      apy,
      tvl,
      pricePerShare: pps,
      risk: "Low",
      description:
        "Conservative yield strategy focused on stablecoin lending with minimal risk exposure",
    };
  }, [totalAssets, pricePerShareRaw, apyRaw]);

  const composition = useMemo(() => {
    if (!allocationsRaw) return [];
    const [protocols, ratios] = allocationsRaw as [string[], bigint[]];
    return protocols.map((proto, i) => ({
      protocol: proto,
      allocation: Number(ratios[i]) / 100,
      amount: "",
    }));
  }, [allocationsRaw]);

  // --- APPROVAL WRITES ---

  const {
    writeContract: writeApprove,
    data: approveHash,
    isPending: isApprovePending,
  } = useWriteContract();

  const { isLoading: isApproveConfirming } = useWaitForTransactionReceipt({
    hash: approveHash,
    query: { enabled: !!approveHash },
  });

  const onApprove = () => {
    if (!address || !amount) return;
    writeApprove({
      address: MOCK_EURC_ADDRESS,
      abi: ERC20_ABI,
      functionName: "approve",
      args: [SAFE_VAULT_ADDRESS, parseUnits(amount, SAFE_VAULT_DECIMALS)],
    });
  };

  // --- VAULT WRITES ---

  const {
    writeContract: writeVault,
    data: txHash,
    isPending,
  } = useWriteContract();

  const { isLoading: isConfirming } = useWaitForTransactionReceipt({
    hash: txHash,
    query: { enabled: !!txHash },
  });

  const onDeposit = () => {
    if (!address || !amount) return;
    writeVault({
      address: SAFE_VAULT_ADDRESS,
      abi: SAFE_VAULT_ABI,
      functionName: "deposit",
      args: [parseUnits(amount, SAFE_VAULT_DECIMALS), address],
    });
  };

  const onWithdraw = () => {
    if (!address || !amount) return;
    writeVault({
      address: SAFE_VAULT_ADDRESS,
      abi: SAFE_VAULT_ABI,
      functionName: "withdraw",
      args: [parseUnits(amount, SAFE_VAULT_DECIMALS), address, address],
    });
  };

  return (
    <div className="min-h-screen w-full px-4 py-8">
      <div className="max-w-7xl mx-auto space-y-6">
        <div className="flex items-start justify-between">
          <div className="space-y-2">
            <div className="flex items-center gap-3">
              <Shield className="h-10 w-10 text-blue-500" />
              <div>
                <h1 className="text-4xl font-bold">{vaultData.name}</h1>
                <p className="text-muted-foreground">
                  {vaultData.description}
                </p>
              </div>
            </div>
          </div>
          <div className="flex gap-3 items-center">
            <input
              className="border px-2 py-1 rounded w-32 text-right"
              placeholder="Amount (USDC)"
              value={amount}
              onChange={(e) => setAmount(e.target.value)}
            />
            <Button
              variant="outline"
              size="lg"
              onClick={onApprove}
              disabled={isApprovePending || isApproveConfirming}
            >
              {isApprovePending || isApproveConfirming ? "Approving…" : "Approve"}
            </Button>
            <Button
              size="lg"
              onClick={onDeposit}
              disabled={isPending || isConfirming}
            >
              {isPending || isConfirming ? "Depositing…" : "Deposit"}
            </Button>
            <Button
              variant="outline"
              size="lg"
              onClick={onWithdraw}
              disabled={isPending || isConfirming}
            >
              {isPending || isConfirming ? "Withdrawing…" : "Withdraw"}
            </Button>
          </div>
        </div>

        <VaultStats vaultData={vaultData} />

        <TabsWrapper composition={composition} vaultData={vaultData} />
      </div>
    </div>
  );
}

function TabsWrapper({
  composition,
  vaultData,
}: {
  composition: { protocol: string; allocation: number; amount: string }[];
  vaultData: { tvl: string };
}) {
  return (
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
  );
}
