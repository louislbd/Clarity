"use client";

import Image from "next/image";
import Link from "next/link";

import { Button } from "../ui/button";
import { ModeToggle } from "../mode-toggle";
import SearchBar from "../SearchBar";

export default function Navbar() {
  return(
    <div className="h-[90px] w-3/4 p-4 mx-auto flex items-center justify-between">
      <Link href="/">
        <div className="flex flex-row items-center gap-x-4">
          <Image src="/logo-clarity-squared.png" alt="Clarity Logo" width={75} height={75} />
          <h1 className="text-3xl font-bold">Clarity</h1>
        </div>
      </Link>
      <div className="flex gap-x-5 items-center">
        <ModeToggle />
        <SearchBar />
        <Button className="cursor-pointer" variant="outline">Docs</Button>
        <Button className="cursor-pointer" variant="outline">About</Button>
        <Link href="/app/earn">
          <Button className="cursor-pointer">Open App</Button>
        </Link>
      </div>
    </div>
  );
}
