import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const DeploySafeVaultModule = buildModule("DeploySafeVault", (m) => {
  const deployer = m.getAccount(0);

  const user = "0xFD68dA8209C15ae3f6ed5e2e5728Ee40A4493e60";

  const mockEURC = m.contract(
    "MockERC20",
    ["Mock EURC", "EURC", 6, deployer, 1_000_000],
    { id: "MockEURC" }
  );

  const mockAavePool = m.contract("MockAavePool", [], { id: "MockAavePool" });

  const aEURC = m.contract(
    "MockERC20",
    ["Aave EURC", "aEURC", 6, deployer, 0],
    { id: "AEURC" }
  );

  m.call(mockAavePool, "setUnderlying", [mockEURC, aEURC], {
    id: "SetUnderlyingEURC",
  });

  const mockYoVault = m.contract("MockYoVault", [mockEURC], {
    id: "MockYoVault",
  });

  const allocations = [
    { protocol: mockAavePool, kind: 1, ratio: 6000 }, // 60%
    { protocol: mockYoVault,  kind: 2, ratio: 4000 }, // 40%
  ];

  const safeVault = m.contract(
    "Safe",
    [mockEURC, deployer, allocations, deployer],
    { id: "SafeVault" }
  );

  m.call(
    mockEURC,
    "mint",
    [user, 100_000n * 10n ** 6n],
    { id: "FundUserWithMockEURC" }
  );

  return {
    mockEURC,
    mockAavePool,
    aEURC,
    mockYoVault,
    safeVault,
  };
});

export default DeploySafeVaultModule;
