const {loadFixture} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const {network} = require("hardhat");
const {anyValue} = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const {expect} = require("chai");
const {ZeroAddress} = require("ethers");

describe("ERC20", function () {
  const amount = 1000n;
  const frozenAmount = 100n;

  async function deployTokenFixture() {
    const [owner, alice, bob, charlie, dave, otherAccount] = await ethers.getSigners();
    const contract = await ethers.getContractFactory("MockERC20");
    const token = await contract.deploy("United States dollar", "USD");
    return {token, owner, alice, bob, charlie, dave, otherAccount};
  }

  describe("Scenarios", function () {
    it("Freeze Alice Account and transfer", async function () {
      const {token, alice, bob} = await loadFixture(deployTokenFixture);
      const aliceAddress = alice.address;
      const bobAddress = bob.address;
      await token.mint(alice, amount);
      await token.freezeAddress(aliceAddress);
      expect(await token.isFrozen(aliceAddress)).to.equal(true);
      await expect(token.connect(alice).transfer(bobAddress, amount)).to.be.reverted;
    });

    it("Freeze Alice Account and transferFrom", async function () {
      const {token, owner, alice, bob} = await loadFixture(deployTokenFixture);
      const spenderAddress = owner.address;
      const aliceAddress = alice.address;
      const bobAddress = bob.address;
      await token.mint(alice, amount);
      await token.connect(alice).approve(spenderAddress, amount);
      await token.freezeAddress(aliceAddress);
      expect(await token.isFrozen(aliceAddress)).to.equal(true);
      await expect(token.connect(owner).transferFrom(aliceAddress, bobAddress, amount)).to.be.reverted;
    });

    it("Freeze Alice Balance and transfer", async function () {
      const {token, alice, bob} = await loadFixture(deployTokenFixture);
      const aliceAddress = alice.address;
      const bobAddress = bob.address;
      await token.mint(alice, amount);
      await token.setFreezeBalance(aliceAddress, frozenAmount);
      expect(await token.getFrozenBalance(aliceAddress)).to.equal(frozenAmount);
      await expect(token.connect(alice).transfer(bobAddress, amount - frozenAmount)).not.to.be.reverted;
      await expect(token.connect(alice).transfer(bobAddress, frozenAmount)).to.be.reverted;
    });

    it("Freeze Alice Balance and transferFrom", async function () {
      const {token, owner, alice, bob} = await loadFixture(deployTokenFixture);
      const spenderAddress = owner.address;
      const aliceAddress = alice.address;
      const bobAddress = bob.address;
      await token.mint(alice, amount);
      await token.connect(alice).approve(spenderAddress, amount);
      await token.setFreezeBalance(aliceAddress, frozenAmount);
      expect(await token.getFrozenBalance(aliceAddress)).to.equal(frozenAmount);
      await expect(token.connect(owner).transferFrom(aliceAddress, bobAddress, amount - frozenAmount)).not.to.be
        .reverted;
      await expect(token.connect(owner).transferFrom(aliceAddress, bobAddress, frozenAmount)).to.be.reverted;
    });
  });
});
