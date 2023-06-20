import { ethers, upgrades  } from "hardhat";
import { config } from "dotenv";

config();

async function main() {
    const TestCrashTokenV2 = await ethers.getContractFactory(
        "TestCrashTokenV2"
    );
    console.log("Upgrading TestCrashTokenTest...");
    const contract = await upgrades.upgradeProxy(
        "0x977C2D75A2b8B748e06c5e85Fd9aAa9EbAb5d48A",
        TestCrashTokenV2
    );

    console.log("TestCrashTokenV2 deployed to:", contract.address);  

    console.log("Upgraded Successfully");
    
    // *** DISCLAIMER ***
    // ONLY MAKE CONTRACT IMMUTABLE IF THE CONTRACT IS AUDITED AND IT IS BULLETPROOF
    // console.log("Transferring proxy admin ownership to the zero address...");

    // const zeroAddress = '0x0000000000000000000000000000000000000000';
    // const admin = await upgrades.admin.getInstance();
    // await admin.transferProxyAdminOwnership(proxyAddress, zeroAddress);

    // console.log("Transferred Successfully. The contract is now immutable.");
    // *** DISCLAIMER ***
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});