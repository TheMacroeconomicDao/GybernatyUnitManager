import { ethers } from 'ethers';
import { readFileSync } from 'fs';
import { join } from 'path';

export class TestSetup {
    private static provider: ethers.JsonRpcProvider;
    
    static async getProvider(): Promise<ethers.JsonRpcProvider> {
        if (!this.provider) {
            this.provider = new ethers.JsonRpcProvider('http://localhost:8545');
        }
        return this.provider;
    }
    
    static async createTestWallets(count: number): Promise<ethers.Wallet[]> {
        const provider = await this.getProvider();
        return Array.from({ length: count }, () => 
            ethers.Wallet.createRandom().connect(provider)
        );
    }
    
    static loadArtifact(contractName: string) {
        const artifactPath = join(__dirname, '../../artifacts', contractName);
        return JSON.parse(readFileSync(`${artifactPath}.json`, 'utf8'));
    }
    
    static async deployContract(
        name: string,
        signer: ethers.Signer,
        ...args: any[]
    ): Promise<ethers.Contract> {
        const artifact = this.loadArtifact(name);
        const factory = new ethers.ContractFactory(
            artifact.abi,
            artifact.bytecode,
            signer
        );
        return factory.deploy(...args);
    }
}