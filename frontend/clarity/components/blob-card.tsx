import * as React from "react"

import { cn } from "@/lib/utils"

function BlobCard({ className, ...props }: React.ComponentProps<"div">) {
  return (
    <div
      data-slot="card"
      className={cn(
        "bg-card text-card-foreground",
        className
      )}
      {...props}
    />
  )
}

function BlobCardContent({ className, ...props }: React.ComponentProps<"div">) {
  return (
    <div
      data-slot="card-content"
      className={cn("px-6", className)}
      {...props}
    />
  )
}

export {
  BlobCard,
  BlobCardContent,
}
