const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const {
  encodeBytes32String,
  ZeroAddress,
  solidityPackedKeccak256,
  getBytes,
  randomBytes,
  hexlify,
} = require("ethers");

describe("eUTXO CBDC", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployTokenFixture() {
    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await ethers.getSigners();

    const contract = await ethers.getContractFactory("MockeUtxoCBDC");
    const token = await contract.deploy("United States dollar", "USD");

    return { token, owner, otherAccount };
  }

  describe("Transfers", function () {
    it("Should mint the funds to the owner", async function () {
      const { token, owner } = await loadFixture(deployTokenFixture);
      const address = await owner.getAddress();
      await token.mint(address, 1000n, encodeBytes32String("test"));
      expect(await token.balanceOf(address)).to.equal(1000n);
    });

    it("Should transfer the funds from the account to other account", async function () {
      const { token, owner, otherAccount } = await loadFixture(
        deployTokenFixture
      );
      const address = await owner.getAddress();
      const otherAddress = await otherAccount.getAddress();
      let tx = await token.mint(address, 1000n, encodeBytes32String("test"));
      tx = await tx.wait();
      const tokenId = tx.logs[0].args[0];
      const hashed = solidityPackedKeccak256(["bytes32"], [tokenId]);
      const signature = await owner.signMessage(getBytes(hashed));
      await token["transfer(address,bytes32,uint256,bytes)"](
        otherAddress,
        tokenId,
        1000n,
        signature
      );
      expect(await token.balanceOf(otherAddress)).to.equal(1000n);
    });

    it("Should fail on transfer with standard ERC20 interface", async function () {
      const { token, owner, otherAccount } = await loadFixture(
        deployTokenFixture
      );
      const address = await owner.getAddress();
      const otherAddress = await otherAccount.getAddress();
      await token.mint(address, 1000n, encodeBytes32String("test"));
      await expect(
        token["transfer(address,uint256)"](otherAddress, 1000n)
      ).to.be.revertedWithCustomError(token, "ERC20TransferNotSupported");
    });

    
    it("Should fail on transferFrom with standard ERC20 interface", async function () {
      const { token, owner, otherAccount } = await loadFixture(
        deployTokenFixture
      );
      const address = await owner.getAddress();
      const otherAddress = await otherAccount.getAddress();
      await token.mint(address, 1000n, encodeBytes32String("test"));
      await expect(
        token["transferFrom(address,address,uint256)"](address, otherAddress, 1000n)
      ).to.be.revertedWithCustomError(token, "ERC20TransferFromNotSupported");
    });
  });

  describe("Restrict", function () {
    it("Should restrict transfer the funds to the other account by frozen tokenId", async function () {
      const { token, owner, otherAccount } = await loadFixture(
        deployTokenFixture
      );
      const address = await owner.getAddress();
      const otherAddress = await otherAccount.getAddress();
      let tx = await token.mint(address, 1000n, encodeBytes32String("test"));
      tx = await tx.wait();
      let tokenId = tx.logs[0].args[0];
      let hashed = solidityPackedKeccak256(["bytes32"], [tokenId]);
      let signature = await owner.signMessage(getBytes(hashed));
      tx = await token["transfer(address,bytes32,uint256,bytes)"](
        otherAddress,
        tokenId,
        100n,
        signature
      );
      tx = await tx.wait();
      tokenId = tx.logs[1].args[0];
      hashed = solidityPackedKeccak256(["bytes32"], [tokenId]);
      signature = await otherAccount.signMessage(getBytes(hashed));
      expect(await token.balanceOf(otherAddress)).to.equal(100n);
      await token.freezeToken(tokenId);
      await expect(
        token
          .connect(otherAccount)
          ["transfer(address,bytes32,uint256,bytes)"](
            address,
            tokenId,
            10n,
            signature
          )
      ).to.be.revertedWithCustomError(token, "TokenFrozen");
    });

    it("Should restrict all transfer the funds to the other account by frozen root tokenId", async function () {
      const { token, owner, otherAccount } = await loadFixture(
        deployTokenFixture
      );
      // const address = await owner.getAddress();
      // const otherAddress = await otherAccount.getAddress();
      // let tx = await token.mint(address, 1000n);
      // tx = await tx.wait();
      // let tokenId = tx.logs[0].args[0];
      // let root = tx.logs[0].args[1];
      // tx = await token["transfer(address,bytes32,uint256)"](
      //   otherAddress,
      //   tokenId,
      //   10n
      // );
      // expect(await token.balanceOf(otherAddress)).to.equal(10n);
      // await token.freezeToken(root);
      // await expect(
      //   token["transfer(address,bytes32,uint256)"](otherAddress, tokenId, 10n)
      // ).to.be.revertedWithCustomError(token, "TokenFrozen");
    });

    it("Should restrict all transfer the funds to the other account by frozen parent tokenId", async function () {
      const { token, owner, otherAccount } = await loadFixture(
        deployTokenFixture
      );
      // const address = await owner.getAddress();
      // const otherAddress = await otherAccount.getAddress();
      // let tx = await token.mint(address, 1000n);
      // tx = await tx.wait();
      // const tokenId = tx.logs[0].args[0];
      // tx = await token["transfer(address,bytes32,uint256)"](
      //   otherAddress,
      //   tokenId,
      //   100n
      // );
      // tx = await tx.wait();
      // const tokenId2 = tx.logs[1].args[0];
      // expect(await token.balanceOf(otherAddress)).to.equal(100n);
      // await token.freezeToken(parent);
      // await expect(
      //   await token["transfer(address,bytes32,uint256)"](
      //     otherAddress,
      //     tokenId2,
      //     10n
      //   )
      // ).to.equal("");
    });
  });
});
