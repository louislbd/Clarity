import Image from "next/image";

export default function Footer() {
  return (
    <div className="min-h-10 w-3/4 mx-auto flex flex-row items-center justify-between py-4 border-t-2">
      <div className="flex flex-col gap-2">
        <Image
          src="/logo-clarity-squared.png"
          alt="LDAO Logo"
          width={50}
          height={50}
        />
        <p className="text-sm text-muted-foreground">
          LiquidityDAO Treasury &copy; {new Date().getFullYear()}. All rights reserved.
        </p>
      </div>
        <div className="flex flex-row gap-4 items-center">
          <a href="https://x.com/" target="_blank" rel="noopener noreferrer" aria-label="X" className="w-7 h-7 relative hover:scale-110 transition">
            <Image src="/logo-x.png" alt="X" fill className="object-contain" />
          </a>
          <a href="https://discord.gg/snnrnWdG" target="_blank" rel="noopener noreferrer" aria-label="Discord" className="w-7 h-7 relative hover:scale-110 transition">
            <Image src="/logo-discord-color.png" alt="Discord" fill className="object-contain" />
          </a>
          <a href="https://github.com/louislbd/liquidityDAO-Treasury" target="_blank" rel="noopener noreferrer" aria-label="GitHub" className="w-7 h-7 relative hover:scale-110 transition">
            <Image src="/logo-github.png" alt="GitHub" fill className="object-contain" />
          </a>
          <a href="https://dune.com/" target="_blank" rel="noopener noreferrer" aria-label="Dune" className="w-7 h-7 relative hover:scale-110 transition">
            <Image src="/logo-dune.png" alt="Dune" fill className="object-contain" />
          </a>
        </div>
    </div>
  );
}
