import { ethers } from 'ethers';
import { readFileSync } from 'fs';
import { join } from 'path';

export interface TestContext {
  provider: ethers.JsonRpcProvider;
  owner: ethers.Wallet;
  users: ethers.Wallet[];
  contracts: {
    gybernatyManager?: ethers.Contract;
    mockToken?: ethers.Contract;
  };
}

export async function setupTestEnvironment(): Promise<TestContext> {
  const provider = new ethers.JsonRpcProvider('http://localhost:8545');
  
  // Create test accounts
  const owner = ethers.Wallet.createRandom().connect(provider);
  const users = Array.from({length: 5}, () => 
    ethers.Wallet.createRandom().connect(provider)
  );

  return {
    provider,
    owner,
    users,
    contracts: {}
  };
}

export function loadContract(name: string) {
  const artifactPath = join(__dirname, '../../artifacts/contracts', name);
  const artifact = JSON.parse(readFileSync(`${artifactPath}.json`, 'utf8'));
  return {
    abi: artifact.abi,
    bytecode: artifact.bytecode
  };
}