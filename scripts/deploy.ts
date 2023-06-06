import { ethers } from "hardhat";
import { config } from "dotenv";

config();

async function main() {
  const BankCrashToken = await ethers.getContractFactory("BankCrashToken");
  const bankCrashToken = await BankCrashToken.deploy();

  await bankCrashToken.deployed();
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});