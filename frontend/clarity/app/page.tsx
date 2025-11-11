import LiquidBlob from "@/components/LiquidBlob";

export default function Home() {
  return (
    <div className="min-h-screen w-3/4 mx-auto my-8">
      <div className="flex flex-col items-center justify-between gap-10">
        <h1 className="text-5xl font-bold font-mono">The shield of your savings</h1>
        <LiquidBlob className="w-3/4" />
      </div>
    </div>
  );
}
