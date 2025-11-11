"use client";

import * as React from "react";
import {
  CommandDialog,
  CommandEmpty,
  CommandGroup,
  CommandInput,
  CommandItem,
  CommandList,
  CommandSeparator,
} from "@/components/ui/command";
import { Input } from "@/components/ui/input";

const suggestions = [
  { label: "Docs", value: "Docs" },
  { label: "About", value: "About" },
  { label: "Audits", value: "Audits" },
];

export default function SearchBar() {
  const [open, setOpen] = React.useState(false);
  const [query, setQuery] = React.useState("");
  const [filtered, setFiltered] = React.useState(suggestions);

  React.useEffect(() => {
    const down = (e: KeyboardEvent) => {
      if (e.key === "k" && (e.metaKey || e.ctrlKey)) {
        e.preventDefault();
        setOpen((state) => !state);
      }
    };
    document.addEventListener("keydown", down);
    return () => document.removeEventListener("keydown", down);
  }, []);

  React.useEffect(() => {
    setFiltered(
      suggestions.filter((s) =>
        s.label.toLowerCase().includes(query.trim().toLowerCase())
      )
    );
  }, [query]);

  return (
    <>
      <div className="relative w-full max-w-md">
        <Input
          placeholder="Search documentation..."
          onFocus={() => setOpen(true)}
          value={query}
          readOnly
          className="w-full pr-16 cursor-pointer"
        />
        <kbd
          aria-label="Shortcut to open command"
          className="absolute right-2 top-1/2 -translate-y-1/2 bg-muted text-muted-foreground pointer-events-none inline-flex h-5 items-center gap-1 rounded border px-1.5 font-mono text-[11px] font-medium opacity-85 select-none"
        >
          <span className="text-xs">⌘</span>K
        </kbd>
      </div>

      <CommandDialog open={open} onOpenChange={setOpen}>
        <CommandInput
          placeholder="Tap a command or search..."
          value={query}
          onValueChange={setQuery}
        />
        <CommandList>
          <CommandEmpty>No results found</CommandEmpty>
          <CommandGroup heading="Suggestions">
            {filtered.map((item) => (
              <CommandItem key={item.value} onSelect={() => setOpen(false)}>
                {item.label}
              </CommandItem>
            ))}
          </CommandGroup>
        </CommandList>
        <CommandSeparator />
      </CommandDialog>
    </>
  );
}
