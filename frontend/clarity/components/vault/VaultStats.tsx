import { Card, CardContent } from "@/components/ui/card";
import { TrendingUp, DollarSign, PieChart, Shield } from "lucide-react";

interface VaultStatsProps {
  vaultData: {
    apy: string;
    tvl: string;
    pricePerShare: string;
    risk: string;
  };
}

export default function VaultStats({ vaultData }: VaultStatsProps) {
  const stats = [
    {
      label: "7D APY",
      value: vaultData.apy,
      icon: TrendingUp,
      color: "text-green-500",
      bgColor: "bg-green-500/10",
    },
    {
      label: "Total Value Locked",
      value: vaultData.tvl,
      icon: DollarSign,
      color: "text-blue-500",
      bgColor: "bg-blue-500/10",
    },
    {
      label: "Price Per Share",
      value: vaultData.pricePerShare,
      icon: PieChart,
      color: "text-purple-500",
      bgColor: "bg-purple-500/10",
    },
    {
      label: "Risk Level",
      value: vaultData.risk,
      icon: Shield,
      color: "text-orange-500",
      bgColor: "bg-orange-500/10",
    },
  ];

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
      {stats.map((stat) => (
        <Card key={stat.label}>
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div className="space-y-1">
                <p className="text-sm text-muted-foreground">{stat.label}</p>
                <p className="text-2xl font-bold">{stat.value}</p>
              </div>
              <div className={`p-3 rounded-lg ${stat.bgColor}`}>
                <stat.icon className={`h-6 w-6 ${stat.color}`} />
              </div>
            </div>
          </CardContent>
        </Card>
      ))}
    </div>
  );
}
