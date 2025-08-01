const {time, loadFixture} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const {anyValue} = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const {network} = require("hardhat");
const {expect} = require("chai");
const {encodeBytes32String, ZeroAddress, solidityPackedKeccak256, getBytes} = require("ethers");
const {amount, freezeAmount, transferFrom, transfer, tokenMetadata} = require("../../utils/constant");

describe("Forest", function () {
  async function deployTokenFixture() {
    const [owner, alice, bob, charlie, dave, otherAccount] = await ethers.getSigners();
    const contract = await ethers.getContractFactory("MockForestV2");
    const token = await contract.deploy(tokenMetadata.name, tokenMetadata.symbol);

    return {token, owner, alice, bob, charlie, otherAccount};
  }

  describe("Scenarios", function () {
    it("Freeze Alice Account and transfer", async function () {
      const {token, alice, bob} = await loadFixture(deployTokenFixture);
      const aliceAddress = alice.address;
      // const bobAddress = bob.address;
      let tx = await token.mint(aliceAddress, amount);
      tx = await tx.wait();
    });

    it("Freeze Alice Account and transferFrom", async function () {
      const {token, alice, bob} = await loadFixture(deployTokenFixture);
    });

    it("Freeze Alice Balance and transfer", async function () {
      const {token, alice, bob} = await loadFixture(deployTokenFixture);
    });

    it("Freeze Alice Balance and transferFrom", async function () {
      const {token, alice, bob} = await loadFixture(deployTokenFixture);
    });

    it("Freeze Alice Token and transfer", async function () {
      const {token, alice, bob} = await loadFixture(deployTokenFixture);
    });

    it("Freeze Alice Token and transferFrom", async function () {
      const {token, alice, bob} = await loadFixture(deployTokenFixture);
    });

    it("Freeze at root and transfer", async function () {
      const {token, alice, bob} = await loadFixture(deployTokenFixture);
    });

    it("Freeze at root and transferFrom", async function () {
      const {token, alice, bob} = await loadFixture(deployTokenFixture);
    });

    it("Freeze at level and transfer", async function () {
      const {token, alice, bob} = await loadFixture(deployTokenFixture);
    });

    it("Freeze at level and transferFrom", async function () {
      const {token, alice, bob} = await loadFixture(deployTokenFixture);
    });
  });
});
