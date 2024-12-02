import { describe, it, expect, beforeEach } from 'vitest';
import { ethers } from 'ethers';
import { TestEnvironment } from './setup/TestEnvironment';

describe('GybernatyUnitManager', () => {
    let owner: ethers.Wallet;
    let users: ethers.Wallet[];
    let contracts: {
        mockToken: ethers.Contract;
        gybernatyManager: ethers.Contract;
    };

    beforeEach(async () => {
        [owner, ...users] = await TestEnvironment.createWallets(5);

        // Deploy contracts
        contracts = {
            mockToken: await TestEnvironment.deployContract('MockToken', owner),
            gybernatyManager: await TestEnvironment.deployContract(
                'GybernatyUnitManager',
                owner,
                contracts.mockToken.address,
                [1000, 2000, 3000, 4000]
            )
        };
    });

    describe('Initialization', () => {
        it('should set the owner as Gybernaty', async () => {
            const GYBERNATY_ROLE = ethers.id('GYBERNATY_ROLE');
            expect(await contracts.gybernatyManager.hasRole(GYBERNATY_ROLE, owner.address))
                .toBe(true);
        });
    });

    describe('User Management', () => {
        it('should allow creating new users', async () => {
            const tx = await contracts.gybernatyManager.proposeCreateUser(
                users[0].address,
                2,
                "Test User",
                "https://example.com"
            );
            
            const receipt = await tx.wait();
            const event = receipt.logs.find(
                log => log.topics[0] === ethers.id('ActionProposed(bytes32,address,uint8,uint256)')
            );
            
            expect(event).toBeDefined();
        });
    });
});