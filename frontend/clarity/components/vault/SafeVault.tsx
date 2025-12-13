"use client";

import { useMemo, useState, useEffect } from "react";
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
import {
  SAFE_VAULT_ADDRESS,
  SAFE_VAULT_ABI,
  EURC_DECIMALS,
} from "@/lib/contracts/safeVault";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";

const MOCK_EURC_ADDRESS = "0x4e30A61fcbe7ca46F6dc98C3256f494a67eBe1AD";

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
  {
    type: "function",
    name: "allowance",
    stateMutability: "view",
    inputs: [
      { name: "owner", type: "address" },
      { name: "spender", type: "address" },
    ],
    outputs: [{ name: "amount", type: "uint256" }],
  },
  {
    type: "function",
    name: "balanceOf",
    stateMutability: "view",
    inputs: [{ name: "owner", type: "address" }],
    outputs: [{ name: "amount", type: "uint256" }],
  },
] as const;

const CSAFE_DECIMALS = 15; // 6 (EURC) + 9 (offset)

export default function SafeVaultPage() {
  const { address } = useAccount();
  const [amount, setAmount] = useState("");
  const [mode, setMode] = useState<"deposit" | "withdraw">("deposit");

  // --- TRANSACTION HOOKS ---

  const {
    writeContract: writeApprove,
    data: approveHash,
    isPending: isApprovePending,
  } = useWriteContract();

  const {
    isLoading: isApproveConfirming,
    isSuccess: isApproveSuccess,
  } = useWaitForTransactionReceipt({
    hash: approveHash,
    query: { enabled: !!approveHash },
  });

  const {
    writeContract: writeVault,
    data: txHash,
    isPending,
  } = useWriteContract();

  const {
    isLoading: isConfirming,
    isSuccess: isTxSuccess,
  } = useWaitForTransactionReceipt({
    hash: txHash,
    query: { enabled: !!txHash },
  });

// --- READS ---

  const { data: totalAssets, refetch: refetchTotalAssets } = useReadContract({
    address: SAFE_VAULT_ADDRESS,
    abi: SAFE_VAULT_ABI,
    functionName: "totalAssets",
  });

  const { data: totalSupply, refetch: refetchTotalSupply } = useReadContract({
    address: SAFE_VAULT_ADDRESS,
    abi: SAFE_VAULT_ABI,
    functionName: "totalSupply",
  });

  const {
    data: pricePerShareRaw,
    refetch: refetchPricePerShare,
  } = useReadContract({
    address: SAFE_VAULT_ADDRESS,
    abi: SAFE_VAULT_ABI,
    functionName: "convertToAssets",
    args: [BigInt(10 ** CSAFE_DECIMALS)], // 1 cSAFE with 15 decimals
  });

  const { data: apyRaw, refetch: refetchApy } = useReadContract({
    address: SAFE_VAULT_ADDRESS,
    abi: SAFE_VAULT_ABI,
    functionName: "getAPY",
  });

  const {
    data: allocationsRaw,
    refetch: refetchAllocations,
  } = useReadContract({
    address: SAFE_VAULT_ADDRESS,
    abi: SAFE_VAULT_ABI,
    functionName: "getAllocations",
  });

  const {
    data: eurcBalanceRaw,
    refetch: refetchEurcBalance,
  } = useReadContract({
    address: MOCK_EURC_ADDRESS,
    abi: ERC20_ABI,
    functionName: "balanceOf",
    args: address ? [address] : undefined,
    query: { enabled: !!address },
  });

  const {
    data: csafeBalanceRaw,
    refetch: refetchCsafeBalance,
  } = useReadContract({
    address: SAFE_VAULT_ADDRESS,
    abi: SAFE_VAULT_ABI,
    functionName: "balanceOf",
    args: address ? [address] : undefined,
    query: { enabled: !!address },
  });

  const {
    data: maxWithdrawRaw,
    refetch: refetchMaxWithdraw,
  } = useReadContract({
    address: SAFE_VAULT_ADDRESS,
    abi: SAFE_VAULT_ABI,
    functionName: "maxWithdraw",
    args: address ? [address] : undefined,
    query: { enabled: !!address },
  });

  const {
    data: allowanceRaw,
    refetch: refetchAllowance,
  } = useReadContract({
    address: MOCK_EURC_ADDRESS,
    abi: ERC20_ABI,
    functionName: "allowance",
    args: address ? [address, SAFE_VAULT_ADDRESS] : undefined,
    query: { enabled: !!address },
  });

  // FIXED: Always parse amount as EURC decimals (both deposit and withdraw)
  const parsedAmountForPreview =
    amount && !Number.isNaN(Number(amount))
      ? parseUnits(amount, EURC_DECIMALS)
      : 0n;

  const {
    data: previewDepositRaw,
    refetch: refetchPreviewDeposit,
  } = useReadContract({
    address: SAFE_VAULT_ADDRESS,
    abi: SAFE_VAULT_ABI,
    functionName: "previewDeposit",
    args:
      mode === "deposit" && parsedAmountForPreview > 0n
        ? [parsedAmountForPreview]
        : undefined,
    query: { enabled: mode === "deposit" && parsedAmountForPreview > 0n },
  });

  const {
    data: previewWithdrawRaw,
    refetch: refetchPreviewWithdraw,
  } = useReadContract({
    address: SAFE_VAULT_ADDRESS,
    abi: SAFE_VAULT_ABI,
    functionName: "previewWithdraw",
    args:
      mode === "withdraw" && parsedAmountForPreview > 0n
        ? [parsedAmountForPreview]
        : undefined,
    query: { enabled: mode === "withdraw" && parsedAmountForPreview > 0n },
  });

  // 🔁 REFRESH READS WHEN VAULT TX CONFIRMS
  useEffect(() => {
    if (!isTxSuccess) return;

    console.log("✅ Vault transaction confirmed! Refetching reads...");

    // Vault state
    refetchTotalAssets();
    refetchTotalSupply();
    refetchPricePerShare();
    refetchApy();
    refetchAllocations();

    // User state
    refetchEurcBalance();
    refetchCsafeBalance();
    refetchMaxWithdraw();
    refetchAllowance();

    // Previews
    if (mode === "deposit") {
      refetchPreviewDeposit();
    } else {
      refetchPreviewWithdraw();
    }

    // Clear input
    setAmount("");
  }, [
    isTxSuccess,
    mode,
    refetchTotalAssets,
    refetchTotalSupply,
    refetchPricePerShare,
    refetchApy,
    refetchAllocations,
    refetchEurcBalance,
    refetchCsafeBalance,
    refetchMaxWithdraw,
    refetchAllowance,
    refetchPreviewDeposit,
    refetchPreviewWithdraw,
  ]);

  // Optional: refresh allowance/balances after approve success
  useEffect(() => {
    if (!isApproveSuccess) return;
    refetchAllowance();
    refetchEurcBalance();
  }, [isApproveSuccess, refetchAllowance, refetchEurcBalance]);

  // Format previews
  const previewDeposit = previewDepositRaw
    ? Number(formatUnits(previewDepositRaw as bigint, CSAFE_DECIMALS))
    : 0;

  const previewWithdraw = previewWithdrawRaw
    ? Number(formatUnits(previewWithdrawRaw as bigint, CSAFE_DECIMALS))
    : 0;

  const vaultData = useMemo(() => {
    const tvl =
      totalAssets != null
        ? `$${Number(
            formatUnits(totalAssets as bigint, EURC_DECIMALS),
          ).toLocaleString()}`
        : "…";

    const pps =
      pricePerShareRaw != null
        ? `$${Number(
            formatUnits(pricePerShareRaw as bigint, EURC_DECIMALS),
          ).toFixed(2)}`
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
      totalAssetsRaw: totalAssets,
      totalSupplyRaw: totalSupply,
    };
  }, [totalAssets, totalSupply, pricePerShareRaw, apyRaw]);

  const composition = useMemo(() => {
    if (!allocationsRaw || !totalAssets) return [];
    const [protocols, ratios] = allocationsRaw as [string[], bigint[]];
    return protocols.map((proto, i) => {
      const ratio = Number(ratios[i]) / 100;
      const amountInVault = (Number(totalAssets) * ratio) / 100;
      return {
        protocol: proto,
        allocation: ratio,
        amountRaw: BigInt(Math.floor(amountInVault)),
      };
    });
  }, [allocationsRaw, totalAssets]);

  const eurcBalance = eurcBalanceRaw
    ? Number(formatUnits(eurcBalanceRaw as bigint, EURC_DECIMALS))
    : 0;

  const maxWithdraw = maxWithdrawRaw
    ? Number(formatUnits(maxWithdrawRaw as bigint, EURC_DECIMALS))
    : 0;

  const csafeBalance = csafeBalanceRaw
    ? Number(formatUnits(csafeBalanceRaw as bigint, CSAFE_DECIMALS))
    : 0;

const parsedAmount =
    amount && !Number.isNaN(Number(amount))
      ? parseUnits(amount, EURC_DECIMALS)
      : 0n;

  const isBusy =
    isPending || isConfirming || isApprovePending || isApproveConfirming;

  const mainButtonLabel =
    mode === "deposit"
      ? isBusy
        ? "Depositing…"
        : "Deposit"
      : isBusy
      ? "Withdrawing…"
      : "Withdraw";

  const onClickMax = () => {
    const maxAmount = mode === "deposit" ? eurcBalance : maxWithdraw;
    if (maxAmount > 0) {
      setAmount(maxAmount.toString());
    }
  };

  const onSubmit = async () => {
    if (!address || !amount || parsedAmount === 0n) return;

    if (mode === "deposit") {
      const allowance = (allowanceRaw as bigint | undefined) ?? 0n;
      if (allowance < parsedAmount) {
        writeApprove(
          {
            address: MOCK_EURC_ADDRESS,
            abi: ERC20_ABI,
            functionName: "approve",
            args: [SAFE_VAULT_ADDRESS, parsedAmount],
          },
          {
            onSuccess: async () => {
              await refetchAllowance();
              writeVault({
                address: SAFE_VAULT_ADDRESS,
                abi: SAFE_VAULT_ABI,
                functionName: "deposit",
                args: [parsedAmount, address],
              });
            },
          },
        );
      } else {
        writeVault({
          address: SAFE_VAULT_ADDRESS,
          abi: SAFE_VAULT_ABI,
          functionName: "deposit",
          args: [parsedAmount, address],
        });
      }
    } else {
      if (Number(amount) > maxWithdraw) {
        console.error(
          `Withdraw amount ${amount} exceeds max ${maxWithdraw}`,
        );
        return;
      }

      writeVault({
        address: SAFE_VAULT_ADDRESS,
        abi: SAFE_VAULT_ABI,
        functionName: "withdraw",
        args: [parsedAmount, address, address],
      });
    }
  };

  return (
    <div className="min-h-screen w-full px-4 py-8">
      <div className="max-w-7xl mx-auto space-y-8">
        {/* Hero Section */}
        <div className="space-y-2">
          <div className="flex items-center gap-3">
            <Shield className="h-10 w-10 text-blue-500" />
            <div>
              <h1 className="text-4xl font-bold">{vaultData.name}</h1>
              <p className="text-sm text-muted-foreground">
                {vaultData.description}
              </p>
            </div>
          </div>

          {(txHash || approveHash) && (
            <div className="flex items-center gap-2 bg-blue-50 border border-blue-200 rounded-xl p-4">
              <div className="w-2 h-2 bg-green-500 rounded-full animate-pulse" />
              <span className="text-sm font-medium text-blue-800">
                {isConfirming || isApproveConfirming
                  ? "⏳ Confirming transaction..."
                  : "✅ Transaction confirmed! Data refreshing..."}
              </span>
            </div>
          )}
        </div>

        {/* Stats + Deposit/Withdraw Row */}
        <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
          {/* Left: Stats Grid */}
          <div className="grid grid-cols-2 gap-4">
            {/* APY */}
            <div className="rounded-2xl border bg-card p-6">
              <p className="text-xs font-medium text-muted-foreground mb-2">
                7D APY
              </p>
              <p className="text-3xl font-bold">{vaultData.apy}</p>
            </div>

            {/* TVL */}
            <div className="rounded-2xl border bg-card p-6">
              <p className="text-xs font-medium text-muted-foreground mb-2">
                Total Value Locked
              </p>
              <p className="text-3xl font-bold">{vaultData.tvl}</p>
            </div>

            {/* Price Per Share */}
            <div className="rounded-2xl border bg-card p-6">
              <p className="text-xs font-medium text-muted-foreground mb-2">
                Price Per Share
              </p>
              <p className="text-3xl font-bold">{vaultData.pricePerShare}</p>
            </div>

            {/* Risk Level */}
            <div className="rounded-2xl border bg-card p-6">
              <p className="text-xs font-medium text-muted-foreground mb-2">
                Risk Level
              </p>
              <p className="text-3xl font-bold">{vaultData.risk}</p>
            </div>
          </div>

          {/* Right: Deposit/Withdraw Card */}
          <div className="rounded-2xl border bg-card p-8">
            <div className="space-y-6">
              <div className="space-y-2">
                <h2 className="text-xl font-semibold">
                  {mode === "deposit" ? "Deposit EURC" : "Withdraw EURC"}
                </h2>
                <p className="text-sm text-muted-foreground">
                  {mode === "deposit"
                    ? "Earn yield by depositing EURC into the Safe Vault"
                    : "Withdraw your EURC by burning cSAFE shares"}
                </p>
              </div>

              {/* Mode Toggle */}
              <div className="flex rounded-lg border bg-muted p-1 w-fit">
                <button
                  type="button"
                  onClick={() => {
                    setMode("deposit");
                    setAmount("");
                  }}
                  className={`px-4 py-2 rounded-md font-medium text-sm transition ${
                    mode === "deposit"
                      ? "bg-background text-foreground shadow-sm"
                      : "text-muted-foreground"
                  }`}
                  disabled={isBusy}
                >
                  Deposit
                </button>
                <button
                  type="button"
                  onClick={() => {
                    setMode("withdraw");
                    setAmount("");
                  }}
                  className={`px-4 py-2 rounded-md font-medium text-sm transition ${
                    mode === "withdraw"
                      ? "bg-background text-foreground shadow-sm"
                      : "text-muted-foreground"
                  }`}
                  disabled={isBusy}
                >
                  Withdraw
                </button>
              </div>

              {/* Amount Input */}
              <div className="space-y-2">
                <div className="flex items-center justify-between">
                  <label className="text-sm font-medium">
                    {mode === "deposit" ? "Deposit Amount" : "Withdraw Amount"}
                  </label>
                  <div className="flex items-center gap-2">
                    <span className="text-sm font-medium text-muted-foreground">
                      {mode === "deposit"
                        ? `Balance: ${eurcBalance.toFixed(2)} EURC`
                        : `Max: ${maxWithdraw.toFixed(2)} EURC`}
                    </span>
                    <button
                      type="button"
                      onClick={onClickMax}
                      className="text-xs font-medium text-blue-500 hover:underline"
                      disabled={isBusy}
                    >
                      Max
                    </button>
                  </div>
                </div>
                <div className="relative flex items-center gap-2 rounded-lg border bg-background px-4 py-3">
                  <input
                    type="number"
                    className="flex-1 bg-transparent text-xl font-semibold outline-none"
                    placeholder="0.00"
                    value={amount}
                    onChange={(e) => setAmount(e.target.value)}
                    disabled={isBusy}
                  />
                  <span className="text-sm font-medium text-muted-foreground">
                    EURC
                  </span>
                </div>
              </div>

              {/* Preview Output */}
              {amount && parsedAmountForPreview > 0n && (
                <div className="space-y-2">
                  <label className="text-sm font-medium">
                    {mode === "deposit"
                      ? "You will receive"
                      : "Shares to burn"}
                  </label>
                  <div className="relative flex items-center gap-2 rounded-lg border bg-muted/50 px-4 py-3 opacity-75">
                    <span className="flex-1 text-xl font-semibold">
                      {mode === "deposit"
                        ? previewDeposit.toFixed(6)
                        : previewWithdraw.toFixed(6)}
                    </span>
                    <span className="text-sm font-medium text-muted-foreground">
                      cSAFE
                    </span>
                  </div>
                </div>
              )}

              {/* Fee Display */}
              <div className="text-xs text-muted-foreground">
                {mode === "deposit" ? "Fees: 1%" : "Fees: 0.5%"}
              </div>

              {/* CTA Button */}
              <Button
                size="lg"
                className="w-full"
                onClick={onSubmit}
                disabled={isBusy || !address || !amount}
              >
                {mainButtonLabel}
              </Button>
            </div>
          </div>
        </div>

        {/* Tabs Section */}
        <TabsWrapper
          composition={composition}
          vaultData={vaultData}
        />
      </div>
    </div>
  );
}

function TabsWrapper({
  composition,
  vaultData,
}: {
  composition: Array<{
    protocol: string;
    allocation: number;
    amountRaw: bigint;
  }>;
  vaultData: {
    tvl: string;
    totalAssetsRaw?: bigint;
    totalSupplyRaw?: bigint;
  };
}) {
  return (
    <Tabs defaultValue="overview" className="space-y-6">
      <TabsList className="grid w-full grid-cols-3 lg:w-[400px]">
        <TabsTrigger value="overview">Overview</TabsTrigger>
        <TabsTrigger value="composition">Composition</TabsTrigger>
        <TabsTrigger value="activity">Activity</TabsTrigger>
      </TabsList>

      <TabsContent value="overview" className="space-y-6">
        <VaultCharts
          totalAssetsRaw={vaultData.totalAssetsRaw}
          totalSupplyRaw={vaultData.totalSupplyRaw}
        />
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
