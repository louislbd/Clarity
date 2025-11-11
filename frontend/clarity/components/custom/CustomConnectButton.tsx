"use client"

import { ConnectButton } from "@rainbow-me/rainbowkit";
import { Button } from "@/components/ui/button";

export default function CustomConnectButton() {
  return (
    <ConnectButton.Custom>
      {({
        account,
        chain,
        openAccountModal,
        openChainModal,
        openConnectModal,
        authenticationStatus,
        mounted,
      }) => {
        // SSR safety
        const ready = mounted && authenticationStatus !== "loading";

        return (
          <div
            {...(!ready ? { "aria-hidden": true } : {})}
            className="flex items-center gap-2"
          >
            {/* Not connected */}
            {!ready ? (
              <Button disabled variant="outline" size="sm">
                Loading...
              </Button>
            ) : !account || !chain ? (
              <Button variant="primary" size="sm" onClick={openConnectModal}>
                Connect Wallet
              </Button>
            ) : chain.unsupported ? (
              <Button
                variant="destructive"
                size="sm"
                onClick={openChainModal}
                className="bg-destructive text-white"
              >
                Wrong network
              </Button>
            ) : (
              <>
                {/* Show Chain Selector */}
                <Button
                  variant="outline"
                  size="sm"
                  onClick={openChainModal}
                  className="flex items-center gap-2"
                >
                  {chain.iconUrl ? (
                    <img
                      src={chain.iconUrl}
                      alt={chain.name}
                      className="h-5 w-5 rounded-full"
                    />
                  ) : null}
                  <span className="text-xs">{chain.name}</span>
                </Button>
                {/* Show Account */}
                <Button
                  variant="ghost"
                  size="sm"
                  onClick={openAccountModal}
                  className="flex items-center gap-2"
                >
                  {account.displayName}
                  {account.displayBalance ? (
                    <span className="ml-2 text-xs text-muted-foreground">
                      {account.displayBalance}
                    </span>
                  ) : null}
                </Button>
              </>
            )}
          </div>
        );
      }}
    </ConnectButton.Custom>
  );
}
