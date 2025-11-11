"use client";

import Image from "next/image";
import Link from "next/link";

import { Button } from "../ui/button";
import { ModeToggle } from "../mode-toggle";
import SearchBar from "../SearchBar";

export default function AppNavbar() {
  return(
    <div className="h-[90px] w-3/4 p-4 mx-auto flex items-center justify-between">
      <Link href="/">
        <div className="flex flex-row items-center gap-x-4">
          <Image src="/logo-clarity-squared.png" alt="LDAO Logo" width={75} height={75} />
          <h1 className="text-3xl font-bold">Clarity</h1>
        </div>
      </Link>
      <div className="flex gap-x-5 items-center">
        <ModeToggle />
        <Button className="cursor-pointer" variant="ghost">Dashboard</Button>
        <Button className="cursor-pointer" variant="ghost">Earn</Button>
        <Link href="/dashboard">
          <Button className="cursor-pointer">Open App</Button>
        </Link>
      </div>
    </div>
  );
}
