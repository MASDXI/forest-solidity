const {time, loadFixture} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const {anyValue} = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const {network} = require("hardhat");
const {expect} = require("chai");
const {encodeBytes32String, ZeroAddress, solidityPackedKeccak256, getBytes, Interface} = require("ethers");
const {amount, freezeAmount, transferFrom, transfer, tokenMetadata} = require("../../utils/constant");
// const {abi} = require("../../../artifacts/contracts/abstracts/ForestTokenV2.sol/ForestTokenV2.json"); 

describe("ForestV2", function () {
  async function deployTokenFixture() {
    const [owner, alice, bob, charlie, dave, otherAccount] = await ethers.getSigners();
    const contract = await ethers.getContractFactory("MockForestV2");
    const token = await contract.deploy(tokenMetadata.name, tokenMetadata.symbol);

    return {token, owner, alice, bob, charlie, otherAccount};
  }

  describe("Scenarios", function () {
    it("Freeze Alice Account and safeTransferFrom", async function () {
      const {token, alice, bob} = await loadFixture(deployTokenFixture);
      const aliceAddress = alice.address;
      // const bobAddress = bob.address;
      let tx = await token.mint(aliceAddress, amount);
      tx = await tx.wait();
      // console.log(tx.logs);
      let abi = [ "event TransactionCreated(bytes32 indexed root, bytes32 id, address indexed from)" ];
      let interface = new Interface(abi);
      let log = interface.parseLog(tx.logs[0]); 
      console.log("🚀 ~ log:", log)
    });

    it("Freeze Alice Balance and safeTransferFrom", async function () {
      const {token, alice, bob} = await loadFixture(deployTokenFixture);
    });

    it("Freeze Alice Token and safeTransferFrom", async function () {
      const {token, alice, bob} = await loadFixture(deployTokenFixture);
    });

    it("Freeze at root and safeTransferFrom", async function () {
      const {token, alice, bob} = await loadFixture(deployTokenFixture);
    });

    it("Freeze at level and safeTransferFrom", async function () {
      const {token, alice, bob} = await loadFixture(deployTokenFixture);
    });
  });
});
