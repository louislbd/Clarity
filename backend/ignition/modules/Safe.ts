import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("Safe", (m) => {
  const safe = m.contract("Safe");

  return { safe };
});
