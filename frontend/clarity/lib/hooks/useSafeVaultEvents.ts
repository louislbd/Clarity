import { useWatchContractEvent } from 'wagmi';
import { useEffect, useState } from 'react';
import { SAFE_VAULT_ADDRESS, SAFE_VAULT_ABI } from '@/lib/contracts/safeVault';
import { formatUnits } from 'viem';
import { baseSepolia } from 'viem/chains';

export interface VaultActivityEvent {
  type: 'deposit' | 'withdraw';
  amount: string; // formatted EURC amount
  address: string;
  timestamp: string; // human-readable (e.g., "2 minutes ago")
  txHash: string;
  blockNumber: number;
  rawAmount: bigint;
}

const STORAGE_KEY = 'clarity_vault_activities';
const MAX_STORED_EVENTS = 50;

export function useSafeVaultEvents() {
  const [activities, setActivities] = useState<VaultActivityEvent[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  // Load from localStorage on mount
  useEffect(() => {
    const stored = localStorage.getItem(STORAGE_KEY);
    if (stored) {
      try {
        const parsed = JSON.parse(stored);
        // Convert rawAmount back to bigint
        const activities = parsed.map((a: any) => ({
          ...a,
          rawAmount: BigInt(a.rawAmount),
        }));
        setActivities(activities);
      } catch (e) {
        console.error('Failed to parse stored activities:', e);
      }
    }
    setIsLoading(false);
  }, []);

  // Listen for Deposit events (wagmi v2)
  useWatchContractEvent({
    address: SAFE_VAULT_ADDRESS,
    abi: SAFE_VAULT_ABI,
    eventName: 'Deposit',
    chainId: baseSepolia.id, // Base Sepolia chain ID
    onLogs: (logs) => {
      logs.forEach((log: any) => {
        const event = log;
        const args = event.args as any;
        if (!args) return;

        const { sender, receiver, assets, shares } = args;

        const newActivity: VaultActivityEvent = {
          type: 'deposit' as const,
          amount: formatUnits(assets as bigint, 6), // EURC has 6 decimals
          address: formatAddress(receiver as `0x${string}`),
          timestamp: 'just now',
          txHash: event.transactionHash,
          blockNumber: Number(event.blockNumber),
          rawAmount: assets as bigint,
        };

        setActivities((prev) => {
          const updated = [newActivity, ...prev];
          const trimmed = updated.slice(0, MAX_STORED_EVENTS);
          persistActivities(trimmed);
          return trimmed;
        });
      });
    },
  });

  // Listen for Withdraw events (wagmi v2)
  useWatchContractEvent({
    address: SAFE_VAULT_ADDRESS,
    abi: SAFE_VAULT_ABI,
    eventName: 'Withdraw',
    chainId: baseSepolia.id, // Base Sepolia chain ID
    onLogs: (logs) => {
      logs.forEach((log: any) => {
        const event = log;
        const args = event.args as any;
        if (!args) return;

        const { sender, receiver, owner, assets, shares } = args;

        const newActivity: VaultActivityEvent = {
          type: 'withdraw' as const,
          amount: formatUnits(assets as bigint, 6), // EURC has 6 decimals
          address: formatAddress(receiver as `0x${string}`),
          timestamp: 'just now',
          txHash: event.transactionHash,
          blockNumber: Number(event.blockNumber),
          rawAmount: assets as bigint,
        };

        setActivities((prev) => {
          const updated = [newActivity, ...prev];
          const trimmed = updated.slice(0, MAX_STORED_EVENTS);
          persistActivities(trimmed);
          return trimmed;
        });
      });
    },
  });

  // Update timestamps every minute (placeholder)
  useEffect(() => {
    const interval = setInterval(() => {
      setActivities((prev) =>
        prev.map((activity) => ({
          ...activity,
          timestamp: getRelativeTime(activity.blockNumber),
        }))
      );
    }, 60000);

    return () => clearInterval(interval);
  }, []);

  return { activities, isLoading };
}

// Helper functions
function formatAddress(address: `0x${string}`): string {
  return `${address.slice(0, 6)}...${address.slice(-4)}`;
}

function persistActivities(activities: VaultActivityEvent[]) {
  localStorage.setItem(
    STORAGE_KEY,
    JSON.stringify(
      activities.map((a) => ({
        ...a,
        rawAmount: a.rawAmount.toString(),
      }))
    )
  );
}

function getRelativeTime(blockNumber: number): string {
  // Placeholder - shows "recently" for now
  // TODO: Add block timestamp lookup for accurate relative time
  return 'recently';
}
