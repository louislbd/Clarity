import type { Abi } from "viem";
import SafeJson from "./Safe.json";

// address of DeploySafeVault#SafeVault on Base Sepolia
export const SAFE_VAULT_ADDRESS =
  "0xa1F7D8F9b2f0549e1ce95cCA5fAa6eBA96154bD0";

export const SAFE_VAULT_ABI = SafeJson.abi as Abi;

// underlying is MockUSDC with 6 decimals
export const SAFE_VAULT_DECIMALS = 6;
