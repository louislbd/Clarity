import type { Abi } from "viem";
import SafeJson from "./Safe.json";

// address of DeploySafeVault#SafeVault on Base Sepolia
export const SAFE_VAULT_ADDRESS = "0xFE41714f17f76Fb198a8331D649F4FbC2f93385c";

export const SAFE_VAULT_ABI = SafeJson.abi as Abi;

// Underlying (MockEURC) decimals
export const EURC_DECIMALS = 6;

// Vault share token (cSAFE) decimals
export const SAFE_VAULT_DECIMALS = 18;
