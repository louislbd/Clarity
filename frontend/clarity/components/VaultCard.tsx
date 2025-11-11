import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { TrendingUp, Shield, Zap } from "lucide-react";

interface Vault {
  name: string;
  apy: string;
  description: string;
  risk: string;
  tvl: string;
  color: "blue" | "purple" | "orange";
}

const colorVariants = {
  blue: "from-blue-500/10 to-blue-600/5 border-blue-500/20",
  purple: "from-purple-500/10 to-purple-600/5 border-purple-500/20",
  orange: "from-orange-500/10 to-orange-600/5 border-orange-500/20",
};

const iconVariants = {
  blue: <Shield className="w-6 h-6 text-blue-500" />,
  purple: <TrendingUp className="w-6 h-6 text-purple-500" />,
  orange: <Zap className="w-6 h-6 text-orange-500" />,
};

export default function VaultCard({ vault }: { vault: Vault }) {
  return (
    <Card className={`bg-gradient-to-br ${colorVariants[vault.color]} hover:shadow-lg transition-all duration-300`}>
      <CardHeader>
        <div className="flex items-center justify-between mb-2">
          {iconVariants[vault.color]}
          <span className="text-xs font-medium px-2 py-1 rounded-full bg-background/50">
            {vault.risk}
          </span>
        </div>
        <CardTitle className="text-2xl">{vault.name}</CardTitle>
        <CardDescription>{vault.description}</CardDescription>
      </CardHeader>
      <CardContent className="space-y-4">
        {/* APY Display */}
        <div className="bg-background/50 rounded-lg p-4">
          <div className="text-sm text-muted-foreground mb-1">
            7D APY
          </div>
          <div className="text-3xl font-bold">{vault.apy}</div>
        </div>

        {/* Stats Grid */}
        <div className="grid grid-cols-2 gap-3">
          <div className="bg-background/30 rounded p-3">
            <div className="text-xs text-muted-foreground mb-1">TVL</div>
            <div className="font-semibold">{vault.tvl}</div>
          </div>
          <div className="bg-background/30 rounded p-3">
            <div className="text-xs text-muted-foreground mb-1">Fee</div>
            <div className="font-semibold">0%</div>
          </div>
        </div>
      </CardContent>
      <CardFooter className="flex gap-2">
        <Button className="flex-1" variant="default">
          Deposit
        </Button>
        <Button className="flex-1" variant="outline">
          Details
        </Button>
      </CardFooter>
    </Card>
  );
}
