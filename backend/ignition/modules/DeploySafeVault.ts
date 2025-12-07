import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { ethers } from "hardhat";

const DeploySafeVaultModule = buildModule("DeploySafeVault", (m) => {
  // Deploy mock ERC-20s
  const mockUSDC = m.contract("MockERC20", [
    "Mock USDC",
    "USDC",
    6,
    m.getAccount(0), // deployer gets initial supply
    1_000_000, // 1M USDC
  ]);

  const mockEURC = m.contract("MockERC20", [
    "Mock EURC",
    "EURC",
    6,
    m.getAccount(0),
    1_000_000, // 1M EURC
  ]);

  // Deploy mock Aave pool
  const mockAavePool = m.contract("MockAavePool", []);

  // Deploy aUSDC token
  const aUSDC = m.contract("MockERC20", [
    "Aave USDC",
    "aUSDC",
    6,
    ethers.ZeroAddress, // no initial supply
    0,
  ]);

  // Deploy aEURC token
  const aEURC = m.contract("MockERC20", [
    "Aave EURC",
    "aEURC",
    6,
    ethers.ZeroAddress,
    0,
  ]);

  // Register assets in Aave pool
  m.call(mockAavePool, "setUnderlying", [mockUSDC, aUSDC]);
  m.call(mockAavePool, "setUnderlying", [mockEURC, aEURC]);

  // Deploy mock Yo EUR vault
  const mockYoVault = m.contract("MockYoVault", [mockEURC]);

  // Deploy Safe vault with allocations
  // For this example: 50% Aave USDC, 50% Yo EUR
  const safeVault = m.contract("Safe", [
    mockUSDC, // underlying asset (the one users deposit)
    m.getAccount(0), // owner (deployer)
    [
      {
        protocol: mockAavePool,
        asset: mockUSDC,
        ratio: 5000, // 50%
      },
      {
        protocol: mockYoVault,
        asset: mockEURC,
        ratio: 5000, // 50%
      },
    ],
    m.getAccount(0), // feeRecipient (deployer for now)
  ]);

  return {
    mockUSDC,
    mockEURC,
    mockAavePool,
    mockYoVault,
    safeVault,
  };
});

export default DeploySafeVaultModule;
