import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const ClarityTreasury = buildModule("ClarityTreasury", (m) => {
    const deployer = m.getAccount(0);
    const teamWallet = "0x9C30F723544ea2355EED2a4dd7403804D33c7996";

    const clarityTreasury = m.contract("ClarityTreasury", [teamWallet], {
        from: deployer,
    });

    return { clarityTreasury };
});

export default ClarityTreasury;