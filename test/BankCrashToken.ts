import { loadFixture, time } from "@nomicfoundation/hardhat-network-helpers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("BankCrashToken", function () {
  async function deployBankCrashTokenFixture() {
    let owner: SignerWithAddress;
    let address1: SignerWithAddress;
    let address2: SignerWithAddress;
    
    [owner, address1, address2] = await ethers.getSigners();
    
    // Deploy our contract
    const BankCrashToken = await ethers.getContractFactory("BankCrashToken");
    const bankCrashToken = await BankCrashToken.deploy();
    await bankCrashToken.deployed();

    // bankCrashToken.mint(owner.address, ethers.utils.parseEther("20000"));

    let balanceOwner = await bankCrashToken.balanceOf(owner.address);
    let balanceAddr1 = await bankCrashToken.balanceOf(address1.address);
    let balanceAddr2 = await bankCrashToken.balanceOf(address2.address);
    
    console.log("\n*--------INITIAL BALANCES--------*");
    console.log("Owner's balance -> ", balanceOwner);
    console.log("address1 of balance -> ", balanceAddr1);
    console.log("address2 of balance -> ", balanceAddr2);
    console.log("*---------------------------------*\n");

    return {bankCrashToken, owner, address1, address2}
  }

  async function deployBankCrashTokenWithAddressesFixture() {
    const { bankCrashToken, owner, address1, address2 } = await loadFixture(deployBankCrashTokenFixture);

    // Token transfers
    await bankCrashToken.connect(owner).transfer(address1.address, ethers.utils.parseEther('100'));
    await bankCrashToken.connect(owner).transfer(address2.address, ethers.utils.parseEther('100'));
    await bankCrashToken.connect(owner).approve(address1.address, ethers.utils.parseEther('100'));
    await bankCrashToken.connect(owner).approve(address2.address, ethers.utils.parseEther('100'));
    
    let balanceOwner = await bankCrashToken.balanceOf(owner.address);
    let balanceAddr1 = await bankCrashToken.balanceOf(address1.address);
    let balanceAddr2 = await bankCrashToken.balanceOf(address2.address);
    
    console.log("\n*--------INITIAL BALANCES--------*");
    console.log("Owner's balance -> ", balanceOwner);
    console.log("address1 of balance -> ", balanceAddr1);
    console.log("address2 of balance -> ", balanceAddr2);
    console.log("*---------------------------------*\n");

    return {bankCrashToken, owner, address1, address2}
  }

  async function deployBankCrashTokenWithStakesFixture() {
    const { bankCrashToken, owner, address1, address2 } = await loadFixture(deployBankCrashTokenWithAddressesFixture);
    
    await bankCrashToken.connect(address1).approve(bankCrashToken.address, ethers.utils.parseEther('100'));
    await bankCrashToken.connect(address1).stake(ethers.utils.parseEther('100'), 12);
    await bankCrashToken.connect(address2).approve(bankCrashToken.address, ethers.utils.parseEther('100'));
    await bankCrashToken.connect(address2).stake(ethers.utils.parseEther('100'), 12);

    let balanceOwner = await bankCrashToken.balanceOf(owner.address);
    let balanceAddr1 = await bankCrashToken.balanceOf(address1.address);
    let balanceAddr2 = await bankCrashToken.balanceOf(address2.address);
    
    console.log("\n*--------Balance & stakes--------*");
    console.log("Owner's balance -> ", balanceOwner);
    console.log("address1 of balance -> ", balanceAddr1);
    console.log("address2 of balance -> ", balanceAddr2);
    console.log("address1's stake amount -> ", (await bankCrashToken.stakes(address1.address, 0)).amount);
    console.log("address2's stake amount -> ", (await bankCrashToken.stakes(address2.address, 0)).amount);
    console.log("*---------------------------------*\n");

    return {bankCrashToken, owner, address1, address2}
  }

  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      const { bankCrashToken, owner } = await loadFixture(deployBankCrashTokenFixture);
      expect(await bankCrashToken.owner()).to.equal(owner.address);
    });

    it("Should be able to transfer tokens from owner to address1", async function () {
      const { bankCrashToken, owner, address1 } = await loadFixture(deployBankCrashTokenFixture);

      const initialOwnerBalance = await bankCrashToken.balanceOf(owner.address);

      await bankCrashToken.connect(owner).transfer(address1.address, ethers.utils.parseEther('100'));
      await bankCrashToken.connect(owner).approve(address1.address, ethers.utils.parseEther('100'));
      const finalOwnerBalance = await bankCrashToken.balanceOf(owner.address);
      expect(initialOwnerBalance.sub(finalOwnerBalance)).to.equal(ethers.utils.parseEther('100'));

      const addr1Balance = await bankCrashToken.balanceOf(address1.address);
      expect(addr1Balance).to.equal(ethers.utils.parseEther('100'));
    });
  });


  describe("Staking", function () {
    it("Should allow users to stake tokens", async function () {
      const { bankCrashToken, owner, address1 } = await loadFixture(deployBankCrashTokenWithAddressesFixture);
      const amountToStake = ethers.utils.parseEther('100');

      // Approve the contract to spend tokens on behalf of address1
      await bankCrashToken.connect(address1).approve(bankCrashToken.address, amountToStake);

      // Now address1 should be able to stake
      await bankCrashToken.connect(address1).stake(amountToStake, 6);

      const stake = await bankCrashToken.stakes(address1.address, 0);
      expect(stake.amount).to.equal(amountToStake);
    });
    
    it("Should fail when users try to stake for less than 3 months", async function () {
      const { bankCrashToken, address1 } = await loadFixture(deployBankCrashTokenWithAddressesFixture);
      await expect(bankCrashToken.connect(address1).stake(100, 0)).to.be.revertedWith("Staking period must be at least 3 months");
      await expect(bankCrashToken.connect(address1).stake(100, 1)).to.be.revertedWith("Staking period must be at least 3 months");
      await expect(bankCrashToken.connect(address1).stake(100, 2)).to.be.revertedWith("Staking period must be at least 3 months");
    });
    
    it("Should fail when users try to stake zero tokens", async function () {
      const { bankCrashToken, address1 } = await loadFixture(deployBankCrashTokenWithAddressesFixture);
      await expect(bankCrashToken.connect(address1).stake(0, 6)).to.be.revertedWith("Staking amount must be greater than zero");
    });

    it("Should emit StakeCreated event when staking was succesful", async function () {
      const { bankCrashToken, owner, address1 } = await loadFixture(deployBankCrashTokenWithAddressesFixture);
      const amountToStake = ethers.utils.parseEther('100');

      // Approve the contract to spend tokens on behalf of address1
      await bankCrashToken.connect(address1).approve(bankCrashToken.address, amountToStake);

      await expect(bankCrashToken.connect(address1).stake(amountToStake, 6)).to.emit(bankCrashToken, "StakeCreated");
    });
  });

  describe("Unstaking", function () {
    it("Should allow users to unstake tokens", async function () {
      const { bankCrashToken, owner, address1 } = await loadFixture(deployBankCrashTokenWithStakesFixture);
      
      await bankCrashToken.connect(address1).unstake(0);

      const stake = await bankCrashToken.stakes(address1.address, 0);
      expect(stake.amount).to.equal(0);
    });

    it("Should apply penalty when user unstakes before 3 months", async function () {
      const { bankCrashToken, owner, address1 } = await loadFixture(deployBankCrashTokenWithStakesFixture);
      const stake = await bankCrashToken.stakes(address1.address, 0);

      BigInt
      const latestTimeStamp = await time.latest();
      
      // 2 months passes
      await time.increaseTo(latestTimeStamp + 3 * 30 * 24 * 60 * 60);

      await bankCrashToken.connect(address1).unstake(0);

      const addr1Balance = (await bankCrashToken.balanceOf(address1.address)).toBigInt();
      expect(addr1Balance).to.be.below(stake.amount.toBigInt());
    });

    it("Should reward user when he unstakes after at least 3 months", async function () {
      const { bankCrashToken, owner, address1 } = await loadFixture(deployBankCrashTokenWithStakesFixture);
      const stake = await bankCrashToken.stakes(address1.address, 0);

      const latestTimeStamp = await time.latest();
      
      // 6 months passes
      await time.increaseTo(latestTimeStamp + 6 * 30 * 24 * 60 * 60);

      // console.log('time should be ->', (await time.latest()));

      await bankCrashToken.connect(address1).unstake(0);

      const addr1Balance = (await bankCrashToken.balanceOf(address1.address)).toBigInt();

      expect(addr1Balance).to.not.equal(BigInt(0));
    });

    it("Should fail when users try to unstake non-existing stakes", async function () {
      const { bankCrashToken, address1 } = await loadFixture(deployBankCrashTokenWithAddressesFixture);
      await expect(bankCrashToken.connect(address1).unstake(9999)).to.be.revertedWith("This stake does not exist");
    });

    it("Should emit StakeRemoved event when unstaking was succesful", async function () {
      const { bankCrashToken, address1 } = await loadFixture(deployBankCrashTokenWithStakesFixture);
      await expect(bankCrashToken.connect(address1).unstake(0)).to.emit(bankCrashToken, "StakeRemoved");
    });
  });
});
