import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { formatUnits } from "viem";
import { EURC_DECIMALS } from "@/lib/contracts/safeVault";

interface VaultChartsProps {
  totalAssetsRaw?: bigint;
  totalSupplyRaw?: bigint;
}

export default function VaultCharts({ totalAssetsRaw, totalSupplyRaw }: VaultChartsProps) {
  const tvlUSD = totalAssetsRaw
    ? Number(formatUnits(totalAssetsRaw, EURC_DECIMALS)).toLocaleString("en-US", {
        minimumFractionDigits: 2,
        maximumFractionDigits: 2,
      })
    : "0.00";

  // Calculate price per share (totalAssets / totalSupply)
  let ppsUSD = "0.000";
  if (totalAssetsRaw && totalSupplyRaw && totalSupplyRaw > 0n) {
    const pps = Number(formatUnits(totalAssetsRaw, EURC_DECIMALS)) /
               Number(formatUnits(totalSupplyRaw, 18));
    ppsUSD = pps.toFixed(3);
  }

  return (
    <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
      {/* Price Per Share Chart */}
      <Card>
        <CardHeader>
          <CardTitle>Price Per Share</CardTitle>
          <CardDescription>Current and historical pricing</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="h-[300px] flex items-center justify-center bg-muted/20 rounded-lg">
            <p className="text-muted-foreground text-center">
              Chart data will be available once historical snapshots are recorded
            </p>
          </div>
          <div className="mt-4 flex justify-between text-sm">
            <span className="text-muted-foreground">Current: ${ppsUSD}</span>
            {/* TODO: Add historical comparison once backend tracks daily PPS */}
          </div>
        </CardContent>
      </Card>

      {/* TVL Chart */}
      <Card>
        <CardHeader>
          <CardTitle>Total Value Locked</CardTitle>
          <CardDescription>Current vault size</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="h-[300px] flex items-center justify-center bg-muted/20 rounded-lg">
            <p className="text-muted-foreground text-center">
              Chart data will be available once historical snapshots are recorded
            </p>
          </div>
          <div className="mt-4 flex justify-between text-sm">
            <span className="font-semibold text-blue-500">Current: ${tvlUSD}</span>
            {/* TODO: Add historical comparison once backend tracks daily TVL */}
          </div>
        </CardContent>
      </Card>

      {/* APY Chart */}
      <Card className="lg:col-span-2">
        <CardHeader>
          <CardTitle>7-Day APY Average</CardTitle>
          <CardDescription>Yield performance trend</CardDescription>
        </CardHeader>
        <CardContent>
          <Tabs defaultValue="7d" className="space-y-4">
            <TabsList>
              <TabsTrigger value="7d">7 Days</TabsTrigger>
              <TabsTrigger value="30d">30 Days</TabsTrigger>
              <TabsTrigger value="90d">90 Days</TabsTrigger>
            </TabsList>
            <TabsContent value="7d">
              <div className="h-[300px] flex items-center justify-center bg-muted/20 rounded-lg">
                <p className="text-muted-foreground text-center">
                  Chart data will be available once historical snapshots are recorded
                </p>
              </div>
            </TabsContent>
            <TabsContent value="30d">
              <div className="h-[300px] flex items-center justify-center bg-muted/20 rounded-lg">
                <p className="text-muted-foreground text-center">
                  Chart data will be available once historical snapshots are recorded
                </p>
              </div>
            </TabsContent>
            <TabsContent value="90d">
              <div className="h-[300px] flex items-center justify-center bg-muted/20 rounded-lg">
                <p className="text-muted-foreground text-center">
                  Chart data will be available once historical snapshots are recorded
                </p>
              </div>
            </TabsContent>
          </Tabs>
          <div className="mt-4 grid grid-cols-3 gap-4 text-center">
            <div>
              <p className="text-sm text-muted-foreground">Min APY</p>
              <p className="text-lg font-semibold">—</p>
            </div>
            <div>
              <p className="text-sm text-muted-foreground">Current APY</p>
              <p className="text-lg font-semibold text-green-500">4.0%</p>
            </div>
            <div>
              <p className="text-sm text-muted-foreground">Max APY</p>
              <p className="text-lg font-semibold">—</p>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
