import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Progress } from "@/components/ui/progress";
import { formatUnits } from "viem";
import { EURC_DECIMALS } from "@/lib/contracts/safeVault";

interface CompositionItem {
  protocol: string;
  allocation: number;
  amountRaw: bigint;
}

interface VaultCompositionProps {
  composition: CompositionItem[];
  totalTVL: string;
}

export default function VaultComposition({ composition, totalTVL }: VaultCompositionProps) {
  return (
    <Card>
      <CardHeader>
        <CardTitle>Vault Composition</CardTitle>
        <CardDescription>Asset allocation across protocols</CardDescription>
      </CardHeader>
      <CardContent>
        <div className="space-y-6">
          {composition.map((item, index) => {
            const formattedAmount = formatUnits(item.amountRaw, EURC_DECIMALS);
            return (
              <div key={index} className="space-y-2">
                <div className="flex items-center justify-between text-sm">
                  <span className="font-medium">{item.protocol}</span>
                  <span className="text-muted-foreground">
                    ${Number(formattedAmount).toLocaleString("en-US", {
                      maximumFractionDigits: 2,
                    })}
                  </span>
                </div>
                <div className="flex items-center gap-3">
                  <Progress value={item.allocation} className="flex-1" />
                  <span className="text-sm font-semibold w-12 text-right">
                    {item.allocation.toFixed(1)}%
                  </span>
                </div>
              </div>
            );
          })}
        </div>
        <div className="mt-6 pt-6 border-t flex justify-between items-center">
          <span className="font-semibold">Total Assets</span>
          <span className="text-xl font-bold">{totalTVL}</span>
        </div>
      </CardContent>
    </Card>
  );
}
