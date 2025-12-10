import type { Abi } from "viem";
import SafeJson from "./Safe.json";

// address of DeploySafeVault#SafeVault on Base Sepolia
export const SAFE_VAULT_ADDRESS =
  "0xe4FB481Efcd40b473E87A3ec8D2C28227f91fe8f";

export const SAFE_VAULT_ABI = SafeJson.abi as Abi;

// Underlying (MockEURC) decimals
export const EURC_DECIMALS = 6;

// Vault share token (cSAFE) decimals
export const SAFE_VAULT_DECIMALS = 18;
