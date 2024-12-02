import { ethers } from 'hardhat';
import { MockToken, GybernatyUnitManager } from '../../typechain-types';
import { SignerWithAddress } from '@nomicfoundation/hardhat-ethers/signers';

export interface TestContext {
    mockToken: MockToken;
    gybernatyManager: GybernatyUnitManager;
    owner: SignerWithAddress;
    users: SignerWithAddress[];
}

export async function setupTestEnvironment(): Promise<TestContext> {
    const [owner, ...users] = await ethers.getSigners();
    
    // Deploy MockToken
    const MockToken = await ethers.getContractFactory('MockToken');
    const mockToken = await MockToken.deploy();
    await mockToken.waitForDeployment();
    
    // Deploy GybernatyUnitManager
    const levelLimits = [1000, 2000, 3000, 4000];
    const GybernatyUnitManager = await ethers.getContractFactory('GybernatyUnitManager');
    const gybernatyManager = await GybernatyUnitManager.deploy(
        await mockToken.getAddress(),
        levelLimits
    );
    await gybernatyManager.waitForDeployment();
    
    return {
        mockToken,
        gybernatyManager,
        owner,
        users
    };
}