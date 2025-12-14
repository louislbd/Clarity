// lib/utils/time.ts
import { publicClient } from '@/lib/viem';

const blockTimestampCache = new Map<number, number>();

export async function getBlockTimestamp(blockNumber: number): Promise<number> {
  if (blockTimestampCache.has(blockNumber)) {
    return blockTimestampCache.get(blockNumber)!;
  }

  const block = await publicClient.getBlock({ blockNumber: BigInt(blockNumber) });
  const timestamp = Number(block.timestamp);
  blockTimestampCache.set(blockNumber, timestamp);
  return timestamp;
}

export function getRelativeTimeFromTimestamp(timestamp: number): string {
  const now = Math.floor(Date.now() / 1000);
  const diff = now - timestamp;

  if (diff < 60) return 'just now';
  if (diff < 3600) return `${Math.floor(diff / 60)}m ago`;
  if (diff < 86400) return `${Math.floor(diff / 3600)}h ago`;
  return `${Math.floor(diff / 86400)}d ago`;
}
