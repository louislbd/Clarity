import type { Abi } from "viem";
import SafeJson from "./Safe.json";

// address of DeploySafeVault#SafeVault on Base Sepolia
export const SAFE_VAULT_ADDRESS = "0x735d86cCD3A9650fbC673F8124319A925899902E";

export const SAFE_VAULT_ABI = SafeJson.abi as Abi;

// Underlying (MockEURC) decimals
export const EURC_DECIMALS = 6;

// Vault share token (cSAFE) decimals
export const SAFE_VAULT_DECIMALS = 18;
