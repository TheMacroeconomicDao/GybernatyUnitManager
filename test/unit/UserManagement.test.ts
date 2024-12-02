import { expect } from 'chai';
import { TestContext, setupTestEnvironment, deployContracts } from '../helpers/setup';

describe('User Management', () => {
  let context: TestContext;

  beforeEach(async () => {
    context = await setupTestEnvironment();
    await deployContracts(context);
  });

  describe('User Creation', () => {
    it('should allow Gybernaty to create users', async () => {
      const { gybernatyManager } = context.contracts;
      const [user1] = context.users;

      const tx = await gybernatyManager.connect(context.owner).proposeCreateUser(
        user1.address,
        2,
        "Test User",
        "https://example.com"
      );
      
      const receipt = await tx.wait();
      const event = receipt.events?.find(e => e.event === 'ActionProposed');
      expect(event).to.not.be.undefined;
    });

    it('should require higher level approvals', async () => {
      const { gybernatyManager } = context.contracts;
      const [initiator, target, approver] = context.users;

      // Create level 3 user first
      await gybernatyManager.connect(context.owner).proposeCreateUser(
        initiator.address,
        3,
        "Level 3 User",
        "https://example.com"
      );

      // Try to create level 2 user
      const tx = await gybernatyManager.connect(initiator).proposeCreateUser(
        target.address,
        2,
        "Level 2 User",
        "https://example.com"
      );
      
      const receipt = await tx.wait();
      const actionId = receipt.events[0].args.actionId;

      // Should fail with insufficient level
      await expect(
        gybernatyManager.connect(approver).approveAction(actionId)
      ).to.be.revertedWith('InsufficientLevel');
    });
  });
});