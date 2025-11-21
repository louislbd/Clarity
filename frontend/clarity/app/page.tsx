import Navbar from "@/components/shared/Navbar";

export default function Home() {
  return (
    <>
      <Navbar />
      <div className="min-h-screen w-3/4 mx-auto mt-14">
        <div className="flex flex-col justify-between gap-10">
          <div>
            <h1 className="text-3xl font-bold font-mono">Invest With Insight, Grow With Clarity</h1>
            <p className="text-lg text-gray-500">Deposit, Save, Earn</p>
          </div>
        </div>
      </div>
    </>
  );
}
