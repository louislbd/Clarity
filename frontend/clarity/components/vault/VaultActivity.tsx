import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { ArrowDownIcon, ArrowUpIcon, ExternalLink } from "lucide-react";

export default function VaultActivity() {
  const activities = [
    {
      type: "deposit",
      amount: "1,250.00 USDC",
      address: "0x1234...5678",
      timestamp: "2 hours ago",
      txHash: "0xabc...def",
    },
    {
      type: "withdraw",
      amount: "850.50 USDC",
      address: "0x8765...4321",
      timestamp: "4 hours ago",
      txHash: "0xdef...abc",
    },
    {
      type: "deposit",
      amount: "5,000.00 USDC",
      address: "0x9876...1234",
      timestamp: "6 hours ago",
      txHash: "0x123...456",
    },
    {
      type: "withdraw",
      amount: "2,340.75 USDC",
      address: "0x4567...8901",
      timestamp: "8 hours ago",
      txHash: "0x789...012",
    },
    {
      type: "deposit",
      amount: "750.25 USDC",
      address: "0x2345...6789",
      timestamp: "12 hours ago",
      txHash: "0x345...678",
    },
  ];

  return (
    <Card>
      <CardHeader>
        <CardTitle>Vault Activity</CardTitle>
        <CardDescription>Recent deposits and withdrawals</CardDescription>
      </CardHeader>
      <CardContent>
        <div className="space-y-4">
          {activities.map((activity, index) => (
            <div
              key={index}
              className="flex items-center justify-between p-4 rounded-lg border hover:bg-muted/50 transition-colors"
            >
              <div className="flex items-center gap-4">
                <div
                  className={`p-2 rounded-full ${
                    activity.type === "deposit"
                      ? "bg-green-500/10 text-green-500"
                      : "bg-red-500/10 text-red-500"
                  }`}
                >
                  {activity.type === "deposit" ? (
                    <ArrowDownIcon className="h-4 w-4" />
                  ) : (
                    <ArrowUpIcon className="h-4 w-4" />
                  )}
                </div>
                <div>
                  <div className="flex items-center gap-2">
                    <Badge variant={activity.type === "deposit" ? "default" : "destructive"}>
                      {activity.type.toUpperCase()}
                    </Badge>
                    <span className="font-medium">{activity.amount}</span>
                  </div>
                  <div className="flex items-center gap-2 text-sm text-muted-foreground mt-1">
                    <span>{activity.address}</span>
                    <span>•</span>
                    <span>{activity.timestamp}</span>
                  </div>
                </div>
              </div>
              <a
                href={`https://basescan.org/tx/${activity.txHash}`}
                target="_blank"
                rel="noopener noreferrer"
                className="text-muted-foreground hover:text-foreground transition-colors"
              >
                <ExternalLink className="h-4 w-4" />
              </a>
            </div>
          ))}
        </div>
      </CardContent>
    </Card>
  );
}
