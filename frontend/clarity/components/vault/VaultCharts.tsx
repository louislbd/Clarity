import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";

export default function VaultCharts() {
  return (
    <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
      {/* Price Per Share Chart */}
      <Card>
        <CardHeader>
          <CardTitle>Price Per Share</CardTitle>
          <CardDescription>Historical price performance</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="h-[300px] flex items-center justify-center bg-muted/20 rounded-lg">
            <p className="text-muted-foreground">Chart placeholder - Price per share over time</p>
          </div>
          <div className="mt-4 flex justify-between text-sm">
            <span className="text-muted-foreground">30 days ago: $1.000</span>
            <span className="font-semibold text-green-500">Current: $1.042 (+4.2%)</span>
          </div>
        </CardContent>
      </Card>

      {/* TVL Chart */}
      <Card>
        <CardHeader>
          <CardTitle>Total Value Locked</CardTitle>
          <CardDescription>Vault growth over time</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="h-[300px] flex items-center justify-center bg-muted/20 rounded-lg">
            <p className="text-muted-foreground">Chart placeholder - TVL growth</p>
          </div>
          <div className="mt-4 flex justify-between text-sm">
            <span className="text-muted-foreground">30 days ago: $2.1M</span>
            <span className="font-semibold text-blue-500">Current: $2.55M (+21.4%)</span>
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
                <p className="text-muted-foreground">Chart placeholder - 7D APY trend</p>
              </div>
            </TabsContent>
            <TabsContent value="30d">
              <div className="h-[300px] flex items-center justify-center bg-muted/20 rounded-lg">
                <p className="text-muted-foreground">Chart placeholder - 30D APY trend</p>
              </div>
            </TabsContent>
            <TabsContent value="90d">
              <div className="h-[300px] flex items-center justify-center bg-muted/20 rounded-lg">
                <p className="text-muted-foreground">Chart placeholder - 90D APY trend</p>
              </div>
            </TabsContent>
          </Tabs>
          <div className="mt-4 grid grid-cols-3 gap-4 text-center">
            <div>
              <p className="text-sm text-muted-foreground">Min APY</p>
              <p className="text-lg font-semibold">3.8%</p>
            </div>
            <div>
              <p className="text-sm text-muted-foreground">Average APY</p>
              <p className="text-lg font-semibold text-green-500">4.2%</p>
            </div>
            <div>
              <p className="text-sm text-muted-foreground">Max APY</p>
              <p className="text-lg font-semibold">4.7%</p>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
