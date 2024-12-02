import { ethers } from 'ethers';
import { TestSetup } from '../setup/TestSetup';

export interface TestContext {
    provider: ethers.JsonRpcProvider;
    accounts: {
        owner: ethers.Wallet;
        users: ethers.Wallet[];
    };
    contracts: {
        mockToken?: ethers.Contract;
        gybernatyManager?: ethers.Contract;
    };
}

export async function createTestContext(): Promise<TestContext> {
    const provider = await TestSetup.getProvider();
    const [owner, ...users] = await TestSetup.createTestWallets(6);
    
    return {
        provider,
        accounts: { owner, users },
        contracts: {}
    };
}

export async function deployTestContracts(context: TestContext) {
    // Deploy MockToken
    context.contracts.mockToken = await TestSetup.deployContract(
        'MockToken',
        context.accounts.owner
    );
    
    // Deploy GybernatyUnitManager
    const levelLimits = [1000, 2000, 3000, 4000];
    context.contracts.gybernatyManager = await TestSetup.deployContract(
        'GybernatyUnitManager',
        context.accounts.owner,
        context.contracts.mockToken.address,
        levelLimits
    );
}