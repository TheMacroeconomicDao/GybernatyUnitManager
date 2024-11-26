import { expect } from "chai";
import { ethers } from "hardhat";
import { TokenManager, UserManager } from "../typechain-types";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

describe("TokenManager", function () {
  let tokenManager: TokenManager;
  let userManager: UserManager;
  let mockToken: any;
  let owner: SignerWithAddress;
  let user1: SignerWithAddress;
  let user2: SignerWithAddress;

  const levelLimits = [1000, 2000, 3000, 4000];

  beforeEach(async function () {
    [owner, user1, user2] = await ethers.getSigners();

    // Deploy mock token
    const MockToken = await ethers.getContractFactory("MockToken");
    mockToken = await MockToken.deploy();
    await mockToken.waitForDeployment();

    // Deploy UserManager
    const UserManager = await ethers.getContractFactory("UserManager");
    userManager = await UserManager.deploy();
    await userManager.waitForDeployment();

    // Deploy TokenManager
    const TokenManager = await ethers.getContractFactory("TokenManager");
    tokenManager = await TokenManager.deploy(
      await mockToken.getAddress(),
      await userManager.getAddress(),
      levelLimits
    );
    await tokenManager.waitForDeployment();

    // Setup roles and users
    const GYBERNATY_ROLE = await userManager.GYBERNATY_ROLE();
    await userManager.grantRole(GYBERNATY_ROLE, owner.address);
    await userManager.createUser(user1.address, 1, "Test User 1", "https://example.com");
  });

  describe("Withdrawals", function () {
    beforeEach(async function () {
      // Fund TokenManager with tokens
      await mockToken.mint(await tokenManager.getAddress(), ethers.parseEther("10000"));
    });

    it("Should allow withdrawal within limits", async function () {
      const amount = 500; // Within level 1 limit
      await tokenManager.connect(user1).withdrawTokens(amount);
      
      expect(await mockToken.balanceOf(user1.address)).to.equal(amount);
    });

    it("Should fail if withdrawal exceeds level limit", async function () {
      const amount = 1500; // Exceeds level 1 limit
      await expect(
        tokenManager.connect(user1).withdrawTokens(amount)
      ).to.be.revertedWithCustomError(tokenManager, "InsufficientWithdrawalBalance");
    });

    it("Should fail if monthly withdrawal count exceeded", async function () {
      const amount = 100;
      // Perform max allowed withdrawals
      for (let i = 0; i < 5; i++) {
        await tokenManager.connect(user1).withdrawTokens(amount);
      }

      // Next withdrawal should fail
      await expect(
        tokenManager.connect(user1).withdrawTokens(amount)
      ).to.be.revertedWithCustomError(tokenManager, "WithdrawalLimitExceeded");
    });
  });
});