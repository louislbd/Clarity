// app/earn/page.tsx
import VaultCard from "@/components/VaultCard";

export default function EarnPage() {
  const vaults = [
    {
      name: "Safe",
      apy: "~4%",
      description: "Mainly USDC",
      risk: "Low",
      tvl: "$2.5M",
      color: "blue",
    },
    {
      name: "Balanced",
      apy: "~7%",
      description: "Diversified assets",
      risk: "Moderate",
      tvl: "$4.2M",
      color: "purple",
    },
    {
      name: "Dynamic",
      apy: "~10%",
      description: "Higher yield strategies",
      risk: "Moderate-High",
      tvl: "$1.8M",
      color: "orange",
    },
  ] as const;

  return (
    <div className="min-h-screen w-full px-4 py-12">
      <div className="max-w-7xl mx-auto">
        <div className="mb-12 text-center">
          <h1 className="text-4xl font-bold mb-4">
            Earn with Clarity Vaults
          </h1>
          <p className="text-lg text-muted-foreground max-w-2xl mx-auto">
            Choose the vault that matches your risk profile and start earning optimized yields across DeFi protocols
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {vaults.map((vault) => (
            <VaultCard key={vault.name} vault={vault} />
          ))}
        </div>

        <div className="mt-16 bg-[var(--card)] border border-[var(--border)] rounded-lg p-8">
          <h2 className="text-2xl font-semibold mb-4">How it works</h2>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <div className="space-y-2">
              <div className="flex items-center gap-2">
                <span className="flex items-center justify-center w-8 h-8 rounded-full bg-primary/10 text-primary font-semibold">
                  1
                </span>
                <h3 className="font-semibold">Deposit Assets</h3>
              </div>
              <p className="text-sm text-muted-foreground pl-10">
                Choose a vault and deposit your assets to start earning
              </p>
            </div>
            <div className="space-y-2">
              <div className="flex items-center gap-2">
                <span className="flex items-center justify-center w-8 h-8 rounded-full bg-primary/10 text-primary font-semibold">
                  2
                </span>
                <h3 className="font-semibold">Auto-Optimization</h3>
              </div>
              <p className="text-sm text-muted-foreground pl-10">
                Clarity reallocates your assets across protocols to maximize yield
              </p>
            </div>
            <div className="space-y-2">
              <div className="flex items-center gap-2">
                <span className="flex items-center justify-center w-8 h-8 rounded-full bg-primary/10 text-primary font-semibold">
                  3
                </span>
                <h3 className="font-semibold">Withdraw Anytime</h3>
              </div>
              <p className="text-sm text-muted-foreground pl-10">
                Redeem your assets plus earned yield whenever you want
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
