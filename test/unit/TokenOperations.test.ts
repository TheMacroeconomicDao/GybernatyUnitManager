import { expect } from 'chai';
import { TestContext, setupTestEnvironment, deployContracts } from '../helpers/setup';

describe('Token Operations', () => {
  let context: TestContext;

  beforeEach(async () => {
    context = await setupTestEnvironment();
    await deployContracts(context);
  });

  describe('Withdrawals', () => {
    it('should allow withdrawals within limits', async () => {
      const { gybernatyManager } = context.contracts;
      const [user] = context.users;

      // Setup user with level 2
      await gybernatyManager.connect(context.owner).proposeCreateUser(
        user.address,
        2,
        "Test User",
        "https://example.com"
      );

      const amount = ethers.utils.parseEther("1.0");
      await gybernatyManager.connect(user).withdrawTokens(amount);

      // Check token balance
      const balance = await gybernatyManager.tokenManager.balanceOf(user.address);
      expect(balance).to.equal(amount);
    });
  });
});