import { ethers, upgrades  } from "hardhat";
import { config } from "dotenv";

config();

async function main() {
  const [ deployer ] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  const TestCrashTokenV1 = await ethers.getContractFactory(
    "TestCrashTokenV1"
  );

  console.log("Deploying TestCrashTokenV1...");
  const contract = await upgrades.deployProxy(TestCrashTokenV1, [], {
    initializer: "initialize",
    kind: "transparent",
  });
  await contract.deployed();
  console.log("TestCrashTokenV1 deployed to:", contract.address);

  const proxyAdmin = await upgrades.admin.getInstance();
  console.log('ProxyAdmin contract address is -> ', proxyAdmin.address);

  console.log('Owner of the ProxyAdmin is now -> ', await proxyAdmin.owner());
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});