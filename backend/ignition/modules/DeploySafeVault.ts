import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const DeploySafeVaultModule = buildModule("DeploySafeVault", (m) => {
  const deployer = m.getAccount(0);
  const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";

  // --- 1. Mock tokens (USDC & EURC) ---

  const mockUSDC = m.contract(
    "MockERC20",
    ["Mock USDC", "USDC", 6, deployer, 1_000_000],
    { id: "MockUSDC" }
  );

  const mockEURC = m.contract(
    "MockERC20",
    ["Mock EURC", "EURC", 6, deployer, 1_000_000],
    { id: "MockEURC" }
  );

  // --- 2. Mock Aave pool & aTokens ---

  const mockAavePool = m.contract("MockAavePool", [], { id: "MockAavePool" });

  const aUSDC = m.contract(
    "MockERC20",
    ["Aave USDC", "aUSDC", 6, deployer, 0],
    { id: "AUSDC" }
  );

  const aEURC = m.contract(
    "MockERC20",
    ["Aave EURC", "aEURC", 6, deployer, 0],
    { id: "AEURC" }
  );

  // Register underlying -> aToken in the mock pool
  m.call(mockAavePool, "setUnderlying", [mockUSDC, aUSDC], { id: "SetUnderlyingUSDC" });
  m.call(mockAavePool, "setUnderlying", [mockEURC, aEURC], { id: "SetUnderlyingEURC" });

  // --- 3. Mock Yo vault (yoEUR) ---

  const mockYoVault = m.contract("MockYoVault", [mockEURC], { id: "MockYoVault" });

  // --- 4. Safe vault with mock allocations ---

  const allocations = [
    {
      protocol: mockAavePool,
      asset: mockUSDC,
      ratio: 5000,
    },
    {
      protocol: mockYoVault,
      asset: mockEURC,
      ratio: 5000,
    },
  ];

  const safeVault = m.contract(
    "Safe",
    [mockUSDC, deployer, allocations, deployer],
    { id: "SafeVault" }
  );

  return {
    mockUSDC,
    mockEURC,
    mockAavePool,
    aUSDC,
    aEURC,
    mockYoVault,
    safeVault,
  };
});

export default DeploySafeVaultModule;
