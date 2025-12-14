import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { ArrowDownIcon, ArrowUpIcon, ExternalLink, Loader2 } from "lucide-react";
import { useSafeVaultEvents } from "@/lib/hooks/useSafeVaultEvents";

export default function VaultActivity() {
  const { activities, isLoading } = useSafeVaultEvents();

  if (isLoading) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>Vault Activity</CardTitle>
          <CardDescription>Recent deposits and withdrawals</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="h-48 flex items-center justify-center">
            <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
          </div>
        </CardContent>
      </Card>
    );
  }

  if (activities.length === 0) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>Vault Activity</CardTitle>
          <CardDescription>Recent deposits and withdrawals</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="h-48 flex items-center justify-center">
            <p className="text-muted-foreground text-center">
              No activity yet. Be the first to deposit into Safe Vault!
            </p>
          </div>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle>Vault Activity</CardTitle>
        <CardDescription>Recent deposits and withdrawals (last 50 transactions)</CardDescription>
      </CardHeader>
      <CardContent>
        <div className="space-y-4">
          {activities.map((activity, index) => (
            <div
              key={`${activity.txHash}-${index}`}
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
                    <Badge
                      variant={activity.type === "deposit" ? "default" : "destructive"}
                    >
                      {activity.type.toUpperCase()}
                    </Badge>
                    <span className="font-medium">
                      {Number(activity.amount).toLocaleString("en-US", {
                        maximumFractionDigits: 2,
                      })}{" "}
                      EURC
                    </span>
                  </div>
                  <div className="flex items-center gap-2 text-sm text-muted-foreground mt-1">
                    <span>{activity.address}</span>
                    <span>•</span>
                    <span>{activity.timestamp}</span>
                  </div>
                </div>
              </div>
              <a
                href={`https://sepolia.basescan.org/tx/${activity.txHash}`}
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
