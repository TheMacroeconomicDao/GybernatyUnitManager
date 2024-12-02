import { expect } from 'chai';
import { TestContext, setupTestEnvironment, deployContracts } from '../helpers/setup';

describe('Approval System', () => {
  let context: TestContext;

  beforeEach(async () => {
    context = await setupTestEnvironment();
    await deployContracts(context);
  });

  describe('Action Approvals', () => {
    it('should require multiple level approvals', async () => {
      const { gybernatyManager } = context.contracts;
      const [initiator, target, approver1, approver2] = context.users;

      // Create users with different levels
      await gybernatyManager.connect(context.owner).proposeCreateUser(
        initiator.address,
        2,
        "Level 2 User",
        "https://example.com"
      );

      await gybernatyManager.connect(context.owner).proposeCreateUser(
        approver1.address,
        3,
        "Level 3 User",
        "https://example.com"
      );

      await gybernatyManager.connect(context.owner).proposeCreateUser(
        approver2.address,
        4,
        "Level 4 User",
        "https://example.com"
      );

      // Propose action
      const tx = await gybernatyManager.connect(initiator).proposeCreateUser(
        target.address,
        1,
        "New User",
        "https://example.com"
      );
      
      const receipt = await tx.wait();
      const actionId = receipt.events[0].args.actionId;

      // Both level 3 and 4 approvals needed
      await gybernatyManager.connect(approver1).approveAction(actionId);
      await gybernatyManager.connect(approver2).approveAction(actionId);

      // Check if user was created
      const exists = await gybernatyManager.userManager.userExists(target.address);
      expect(exists).to.be.true;
    });
  });
});