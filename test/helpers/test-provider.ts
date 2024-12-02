import { ethers } from 'ethers';

export class TestProvider extends ethers.JsonRpcProvider {
  private constructor() {
    super('http://localhost:8545');
  }

  private static instance: TestProvider;

  public static getInstance(): TestProvider {
    if (!TestProvider.instance) {
      TestProvider.instance = new TestProvider();
    }
    return TestProvider.instance;
  }

  async createTestAccounts(count: number): Promise<ethers.Wallet[]> {
    return Array.from({length: count}, () => 
      ethers.Wallet.createRandom().connect(this)
    );
  }
}