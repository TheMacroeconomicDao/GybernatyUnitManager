import { TestProvider } from './helpers/test-provider';
import { ContractLoader } from './helpers/contract-loader';
import { ethers } from 'ethers';

export interface TestContext {
  provider: TestProvider;
  accounts: {
    owner: ethers.Wallet;
    users: ethers.Wallet[];
  };
  contracts: {
    mockToken?: ethers.Contract;
    gybernatyManager?: ethers.Contract;
  };
}

export async function setupTestEnvironment(): Promise<TestContext> {
  const provider = TestProvider.getInstance();
  const [owner, ...users] = await provider.createTestAccounts(6);

  return {
    provider,
    accounts: { owner, users },
    contracts: {}
  };
}

export async function deployTestContracts(context: TestContext) {
  // Deploy MockToken
  const mockToken = await ContractLoader.deployContract(
    'MockToken',
    context.accounts.owner
  );

  // Deploy GybernatyUnitManager
  const levelLimits = [1000, 2000, 3000, 4000];
  const gybernatyManager = await ContractLoader.deployContract(
    'GybernatyUnitManager',
    context.accounts.owner,
    mockToken.address,
    levelLimits
  );

  context.contracts = {
    mockToken,
    gybernatyManager
  };
}