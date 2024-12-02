import { describe, it, expect, beforeEach } from 'vitest';
import { ethers } from 'hardhat';
import { GybernatyUnitManager, MockToken } from '../../typechain-types';
import { SignerWithAddress } from '@nomicfoundation/hardhat-ethers/signers';
import { Constants } from '../../contracts/libraries/Constants';

describe('GybernatyUnitManager', () => {
    let gybernatyManager: GybernatyUnitManager;
    let mockToken: MockToken;
    let owner: SignerWithAddress;
    let user1: SignerWithAddress;
    let user2: SignerWithAddress;
    
    beforeEach(async () => {
        [owner, user1, user2] = await ethers.getSigners();
        
        // Deploy MockToken
        const MockToken = await ethers.getContractFactory('MockToken');
        mockToken = await MockToken.deploy();
        await mockToken.waitForDeployment();
        
        // Deploy GybernatyUnitManager
        const levelLimits = [1000, 2000, 3000, 4000];
        const GybernatyUnitManager = await ethers.getContractFactory('GybernatyUnitManager');
        gybernatyManager = await GybernatyUnitManager.deploy(
            await mockToken.getAddress(),
            levelLimits
        );
        await gybernatyManager.waitForDeployment();
    });
    
    describe('Initialization', () => {
        it('should set up roles correctly', async () => {
            const GYBERNATY_ROLE = await gybernatyManager.GYBERNATY_ROLE();
            expect(await gybernatyManager.hasRole(GYBERNATY_ROLE, owner.address)).to.be.true;
        });
        
        it('should initialize managers', async () => {
            expect(await gybernatyManager.userManager()).to.not.equal(ethers.ZeroAddress);
            expect(await gybernatyManager.tokenManager()).to.not.equal(ethers.ZeroAddress);
            expect(await gybernatyManager.approvalManager()).to.not.equal(ethers.ZeroAddress);
        });
    });
    
    describe('Join Gybernaty', () => {
        it('should allow joining with sufficient BNB', async () => {
            const tx = await gybernatyManager.connect(user1).joinGybernaty({
                value: Constants.BNB_AMOUNT
            });
            
            const receipt = await tx.wait();
            const event = receipt?.logs.find(
                log => log.topics[0] === ethers.id('GybernatyJoined(address,uint256,uint256)')
            );
            
            expect(event).to.not.be.undefined;
            expect(await gybernatyManager.hasRole(Constants.GYBERNATY_ROLE, user1.address)).to.be.true;
        });
        
        it('should allow joining with GBR tokens', async () => {
            await mockToken.mint(user1.address, Constants.GBR_TOKEN_AMOUNT);
            await mockToken.connect(user1).approve(gybernatyManager.address, Constants.GBR_TOKEN_AMOUNT);
            
            await gybernatyManager.connect(user1).joinGybernaty();
            expect(await gybernatyManager.hasRole(Constants.GYBERNATY_ROLE, user1.address)).to.be.true;
        });
    });
});