const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("UserManager", function () {
  let userManager;
  let owner;
  let addr1;
  let addr2;

  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();
    
    const UserManager = await ethers.getContractFactory("UserManager");
    userManager = await UserManager.deploy();
    await userManager.waitForDeployment();
    
    // Grant GYBERNATY_ROLE to owner
    const GYBERNATY_ROLE = await userManager.GYBERNATY_ROLE();
    await userManager.grantRole(GYBERNATY_ROLE, owner.address);
  });

  describe("User Creation", function () {
    it("Should create a new user", async function () {
      await userManager.createUser(addr1.address, 1, "Test User", "https://example.com");
      
      const user = await userManager.getUser(addr1.address);
      expect(user.name).to.equal("Test User");
      expect(user.level).to.equal(1);
      expect(user.exists).to.be.true;
    });

    it("Should fail if user already exists", async function () {
      await userManager.createUser(addr1.address, 1, "Test User", "https://example.com");
      
      await expect(
        userManager.createUser(addr1.address, 1, "Test User 2", "https://example.com")
      ).to.be.revertedWithCustomError(userManager, "UserAlreadyExists");
    });

    it("Should fail if level is invalid", async function () {
      await expect(
        userManager.createUser(addr1.address, 0, "Test User", "https://example.com")
      ).to.be.revertedWithCustomError(userManager, "InvalidLevel");

      await expect(
        userManager.createUser(addr1.address, 5, "Test User", "https://example.com")
      ).to.be.revertedWithCustomError(userManager, "InvalidLevel");
    });
  });
});