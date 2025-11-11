"use client";

import Image from "next/image";
import Link from "next/link";

import { Button } from "../ui/button";
import { ModeToggle } from "../mode-toggle";

export default function AppNavbar() {
  const tvl = "$12.3M";

  return (
    <div className="h-[90px] w-3/4 p-4 mx-auto flex items-center justify-between">
      <Link href="/">
        <div className="flex flex-row items-center gap-x-4">
          <Image src="/logo-clarity-squared.png" alt="Clarity Logo" width={75} height={75} />
          <h1 className="text-3xl font-bold">Clarity</h1>
        </div>
      </Link>
      <div className="flex items-center gap-x-7">
        <ModeToggle />
        <Button className="cursor-pointer" variant="ghost">Dashboard</Button>
        <Button className="cursor-pointer" variant="ghost">Earn</Button>
        <p className="text-muted-foreground">TVL: {tvl}</p>
        <Link href="#">
          <Button className="cursor-pointer">Connect Wallet</Button>
        </Link>
      </div>
    </div>
  );
}
