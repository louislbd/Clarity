"use client";

import Image from "next/image";
import { Button } from "../ui/button";
import SearchBar from "../SearchBar";
import { ModeToggle } from "../mode-toggle";

export default function Navbar() {
  return(
    <div className="h-[90px] w-3/4 p-4 mx-auto flex items-center justify-between">
        <div className="flex flex-row items-center gap-x-4">
            <Image src="/logo-clarity-squared.png" alt="LDAO Logo" width={75} height={75} />
            <h1 className="text-3xl font-bold">Clarity</h1>
        </div>
        <div className="flex gap-x-5 items-center">
            <ModeToggle />
            <SearchBar />
            <Button className="cursor-pointer" variant="outline">Docs</Button>
            <Button className="cursor-pointer" variant="outline">About</Button>
            <Button className="cursor-pointer">Open App</Button>
        </div>
    </div>
  );
}
