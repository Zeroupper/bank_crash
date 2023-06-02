import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { parseEther } from "ethers/lib/utils";
import { ethers } from "hardhat";

describe("BankCrashToken", function () {
  async function deployBankCrashTokenFixture() {
    let owner: SignerWithAddress;
    let address1: SignerWithAddress;
    let address2: SignerWithAddress;

    const BankCrashTokenTest = await ethers.getContractFactory("BankCrashTokenTest");

    [owner, address1, address2] = await ethers.getSigners();

    // Deploy our contract
    const bankCrashTokentest = await BankCrashTokenTest.deploy();
    await bankCrashTokentest.deployed();

    bankCrashTokentest.mint(owner.address, ethers.utils.parseEther("20000"));

    let balanceOwner = await bankCrashTokentest.balanceOf(owner.address);
    let balanceAddr1 = await bankCrashTokentest.balanceOf(address1.address);
    let balanceAddr2 = await bankCrashTokentest.balanceOf(address2.address);
    
    console.log("\n*--------INITIAL BALANCES--------*");
    console.log("Owner's balance -> ", balanceOwner);
    console.log("address1 of balance -> ", balanceAddr1);
    console.log("address2 of balance -> ", balanceAddr2);
    console.log("*---------------------------------*\n");

    return {bankCrashTokentest, owner, address1, address2}
  }

  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      const { bankCrashTokentest, owner } = await loadFixture(deployBankCrashTokenFixture);
      expect(await bankCrashTokentest.owner()).to.equal(owner.address);
    });

    it("Should be able to transfer tokens from owner to address1", async function () {
      const { bankCrashTokentest, owner, address1 } = await loadFixture(deployBankCrashTokenFixture);

      const initialOwnerBalance = await bankCrashTokentest.balanceOf(owner.address);

      await bankCrashTokentest.connect(owner).transfer(address1.address, ethers.utils.parseEther('100'));
      await bankCrashTokentest.connect(owner).approve(address1.address, ethers.utils.parseEther('100'));

      const finalOwnerBalance = await bankCrashTokentest.balanceOf(owner.address);
      expect(initialOwnerBalance.sub(finalOwnerBalance)).to.equal(ethers.utils.parseEther('100'));

      const addr1Balance = await bankCrashTokentest.balanceOf(address1.address);
      expect(addr1Balance).to.equal(ethers.utils.parseEther('100'));
    });
  });


  describe("Staking", function () {
    it("Should allow users to stake tokens", async function () {
      const { bankCrashTokentest, owner, address1 } = await loadFixture(deployBankCrashTokenFixture);
      const amountToStake = ethers.utils.parseEther('100');
      
      await bankCrashTokentest.connect(owner).transfer(address1.address, ethers.utils.parseEther('100'));
      await bankCrashTokentest.connect(owner).approve(address1.address, ethers.utils.parseEther('100'));

      // Approve the contract to spend tokens on behalf of address1
      await bankCrashTokentest.connect(address1).approve(bankCrashTokentest.address, amountToStake);

      // Now you should be able to stake
      await bankCrashTokentest.connect(address1).stake(amountToStake, 6);

      const stake = await bankCrashTokentest.stakes(address1.address, 0);
      expect(stake.amount).to.equal(amountToStake);
    });

    it("Should fail when users try to stake zero tokens", async function () {
      const { bankCrashTokentest, address1 } = await loadFixture(deployBankCrashTokenFixture);
      await expect(bankCrashTokentest.connect(address1).stake(0, 6)).to.be.revertedWith("Staking amount must be greater than zero");
    });
});

describe("Unstaking", function () {
    // it("Should allow users to unstake tokens", async function () {
    //   const { bankCrashTokentest, owner, address1 } = await loadFixture(deployBankCrashTokenFixture);
    //   const amountToStake = ethers.utils.parseEther('1000');

    //   await bankCrashTokentest.connect(owner).transfer(address1.address, ethers.utils.parseEther('100'));
    //   await bankCrashTokentest.connect(owner).approve(address1.address, ethers.utils.parseEther('100'));

    //   await bankCrashTokentest.connect(address1).unstake(0);
    //   const stake = await bankCrashTokentest.stakes(address1.address, 0);
    //   expect(stake.amount).to.equal(0);
    // });

    it("Should fail when users try to unstake non-existing stakes", async function () {
      const { bankCrashTokentest, address1 } = await loadFixture(deployBankCrashTokenFixture);
      await expect(bankCrashTokentest.connect(address1).unstake(9999)).to.be.revertedWith("This stake does not exist");
    });
});

});

