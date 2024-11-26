import { expect } from "chai";
import { ethers } from "hardhat";
import { ApprovalManager } from "../typechain-types";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { time } from "@nomicfoundation/hardhat-network-helpers";

describe("ApprovalManager", function () {
  let approvalManager: ApprovalManager;
  let owner: SignerWithAddress;
  let user1: SignerWithAddress;
  let user2: SignerWithAddress;
  let user3: SignerWithAddress;

  beforeEach(async function () {
    [owner, user1, user2, user3] = await ethers.getSigners();

    const ApprovalManager = await ethers.getContractFactory("ApprovalManager");
    approvalManager = await ApprovalManager.deploy();
    await approvalManager.waitForDeployment();

    // Grant GYBERNATY_ROLE to owner
    const GYBERNATY_ROLE = await approvalManager.GYBERNATY_ROLE();
    await approvalManager.grantRole(GYBERNATY_ROLE, owner.address);
  });

  describe("Action Approvals", function () {
    let actionId: string;

    beforeEach(async function () {
      // Create a sample action ID
      actionId = ethers.keccak256(
        ethers.solidityPacked(
          ["string", "address"],
          ["CREATE_USER", user1.address]
        )
      );
    });

    it("Should allow Gybernaty to approve actions", async function () {
      const approved = await approvalManager.connect(owner).addApproval(actionId);
      expect(approved).to.be.true;
    });

    it("Should fail if action is already approved", async function () {
      await approvalManager.connect(owner).addApproval(actionId);
      await expect(
        approvalManager.connect(owner).addApproval(actionId)
      ).to.be.revertedWithCustomError(approvalManager, "AlreadyApproved");
    });

    it("Should fail if action has expired", async function () {
      // Move time forward by 8 days
      await time.increase(8 * 24 * 60 * 60);

      await expect(
        approvalManager.connect(owner).addApproval(actionId)
      ).to.be.revertedWithCustomError(approvalManager, "ActionExpired");
    });

    it("Should emit ActionApproved event", async function () {
      await expect(approvalManager.connect(owner).addApproval(actionId))
        .to.emit(approvalManager, "ActionApproved")
        .withArgs(actionId, owner.address, await time.latest());
    });
  });

  describe("Action Details", function () {
    it("Should return correct action details", async function () {
      const actionId = ethers.keccak256(
        ethers.solidityPacked(
          ["string", "address"],
          ["CREATE_USER", user1.address]
        )
      );

      const details = await approvalManager.getActionDetails(actionId);
      expect(details.isPending).to.be.false;
      expect(details.approvalsCount).to.equal(0);
    });
  });
});