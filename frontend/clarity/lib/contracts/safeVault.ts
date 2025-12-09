import type { Abi } from "viem";
import SafeJson from "./Safe.json";

// address of DeploySafeVault#SafeVault on Base Sepolia
export const SAFE_VAULT_ADDRESS =
  "0xd81BD2Da8f01E9cc3657C8168c4d7Df8Fbe78bA8";

export const SAFE_VAULT_ABI = SafeJson.abi as Abi;

// underlying is MockUSDC with 6 decimals
export const SAFE_VAULT_DECIMALS = 6;
