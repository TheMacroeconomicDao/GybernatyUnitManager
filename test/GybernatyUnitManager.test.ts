import { expect } from "chai";
import { ethers } from "hardhat";
import { 
  GybernatyUnitManager,
  MockToken,
  UserManager,
  TokenManager,
  ApprovalManager 
} from "../typechain-types";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { time } from "@nomicfoundation/hardhat-network-helpers";

describe("GybernatyUnitManager", function () {
  let gybernatyManager: GybernatyUnitManager;
  let mockToken: MockToken;
  let owner: SignerWithAddress;
  let gybernaty: SignerWithAddress;
  let user1: SignerWithAddress;
  let user2: SignerWithAddress;
  let user3: SignerWithAddress;

  const levelLimits = [1000, 2000, 3000, 4000];
  const GYBERNATY_ROLE = ethers.keccak256(ethers.toUtf8Bytes("GYBERNATY_ROLE"));

  beforeEach(async function () {
    [owner, gybernaty, user1, user2, user3] = await ethers.getSigners();

    // Deploy mock token
    const MockToken = await ethers.getContractFactory("MockToken");
    mockToken = await MockToken.deploy();

    // Deploy GybernatyUnitManager
    const GybernatyUnitManager = await ethers.getContractFactory("GybernatyUnitManager");
    gybernatyManager = await GybernatyUnitManager.deploy(
      await mockToken.getAddress(),
      levelLimits
    );

    // Mint tokens for testing
    await mockToken.mint(gybernaty.address, ethers.parseEther("2000000"));
    await mockToken.connect(gybernaty).approve(
      await gybernatyManager.getAddress(),
      ethers.parseEther("1000000")
    );
  });

  describe("Initialization", function () {
    it("Should initialize with correct parameters", async function () {
      expect(await gybernatyManager.hasRole(GYBERNATY_ROLE, owner.address)).to.be.true;
      expect(await gybernatyManager.tokenManager()).to.not.equal(ethers.ZeroAddress);
      expect(await gybernatyManager.userManager()).to.not.equal(ethers.ZeroAddress);
      expect(await gybernatyManager.approvalManager()).to.not.equal(ethers.ZeroAddress);
    });
  });

  describe("Joining as Gybernaty", function () {
    it("Should allow joining with GBR tokens", async function () {
      await gybernatyManager.connect(gybernaty).joinGybernaty();
      expect(await gybernatyManager.hasRole(GYBERNATY_ROLE, gybernaty.address)).to.be.true;
    });

    it("Should allow joining with BNB", async function () {
      await gybernatyManager.connect(user1).joinGybernaty({ 
        value: ethers.parseEther("1000") 
      });
      expect(await gybernatyManager.hasRole(GYBERNATY_ROLE, user1.address)).to.be.true;
    });

    it("Should fail with insufficient payment", async function () {
      await expect(
        gybernatyManager.connect(user1).joinGybernaty({ 
          value: ethers.parseEther("100") 
        })
      ).to.be.revertedWith("Insufficient payment");
    });
  });

  describe("User Management", function () {
    beforeEach(async function () {
      await gybernatyManager.connect(gybernaty).joinGybernaty();
    });

    it("Should propose and create new user", async function () {
      const tx = await gybernatyManager.connect(gybernaty).proposeCreateUser(
        user1.address,
        2,
        "Test User",
        "https://example.com"
      );
      
      const receipt = await tx.wait();
      const event = receipt?.logs.find(
        log => log.topics[0] === ethers.id("ActionProposed(bytes32,address,uint32)")
      );
      
      expect(event).to.not.be.undefined;
      
      const actionId = event?.topics[1];
      await gybernatyManager.connect(gybernaty).approveAction(actionId);
      
      const userLevel = await gybernatyManager.userManager.getUserLevel(user1.address);
      expect(userLevel).to.equal(2);
    });

    it("Should require multiple approvals for non-Gybernaty proposals", async function () {
      // Create level 3 user
      await gybernatyManager.connect(gybernaty).proposeCreateUser(
        user2.address,
        3,
        "Level 3 User",
        "https://example.com"
      );
      
      // Try to create level 2 user from level 3
      const tx = await gybernatyManager.connect(user2).proposeCreateUser(
        user3.address,
        2,
        "Level 2 User",
        "https://example.com"
      );
      
      const receipt = await tx.wait();
      const actionId = receipt?.logs[0].topics[1];
      
      // Should require approval from level 4 or Gybernaty
      await expect(
        gybernatyManager.connect(user1).approveAction(actionId)
      ).to.be.revertedWithCustomError(gybernatyManager, "UnauthorizedApprover");
      
      // Should succeed with Gybernaty approval
      await gybernatyManager.connect(gybernaty).approveAction(actionId);
    });
  });

  describe("Token Management", function () {
    beforeEach(async function () {
      await gybernatyManager.connect(gybernaty).joinGybernaty();
      
      // Create test user with level 2
      const tx = await gybernatyManager.connect(gybernaty).proposeCreateUser(
        user1.address,
        2,
        "Test User",
        "https://example.com"
      );
      
      const receipt = await tx.wait();
      const actionId = receipt?.logs[0].topics[1];
      await gybernatyManager.connect(gybernaty).approveAction(actionId);
      
      // Fund contract with tokens
      await mockToken.mint(
        await gybernatyManager.getAddress(),
        ethers.parseEther("10000")
      );
    });

    it("Should allow withdrawals within limits", async function () {
      const amount = 1500; // Within level 2 limit
      await gybernatyManager.connect(user1).withdrawTokens(amount);
      expect(await mockToken.balanceOf(user1.address)).to.equal(amount);
    });

    it("Should fail if withdrawal exceeds level limit", async function () {
      const amount = 2500; // Exceeds level 2 limit
      await expect(
        gybernatyManager.connect(user1).withdrawTokens(amount)
      ).to.be.revertedWithCustomError(gybernatyManager, "InsufficientWithdrawalBalance");
    });

    it("Should enforce monthly withdrawal limits", async function () {
      const amount = 1000;
      
      // First two withdrawals should succeed
      await gybernatyManager.connect(user1).withdrawTokens(amount);
      await gybernatyManager.connect(user1).withdrawTokens(amount);
      
      // Third withdrawal should fail
      await expect(
        gybernatyManager.connect(user1).withdrawTokens(amount)
      ).to.be.revertedWithCustomError(gybernatyManager, "WithdrawalLimitExceeded");
      
      // Move time forward one month
      await time.increase(30 * 24 * 60 * 60);
      
      // Should allow withdrawal in new month
      await gybernatyManager.connect(user1).withdrawTokens(amount);
    });
  });

  describe("Action Expiration", function () {
    it("Should expire actions after timeout", async function () {
      const tx = await gybernatyManager.connect(gybernaty).proposeCreateUser(
        user1.address,
        2,
        "Test User",
        "https://example.com"
      );
      
      const receipt = await tx.wait();
      const actionId = receipt?.logs[0].topics[1];
      
      // Move time forward beyond timeout
      await time.increase(8 * 24 * 60 * 60);
      
      await expect(
        gybernatyManager.connect(gybernaty).approveAction(actionId)
      ).to.be.revertedWithCustomError(gybernatyManager, "ActionExpired");
    });
  });
});