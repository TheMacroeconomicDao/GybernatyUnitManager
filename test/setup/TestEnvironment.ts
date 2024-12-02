import { ethers } from 'ethers';
import { join } from 'path';
import { readFileSync } from 'fs';

export class TestEnvironment {
    private static provider = new ethers.JsonRpcProvider('http://localhost:8545');
    
    static async createWallets(count: number): Promise<ethers.Wallet[]> {
        return Array.from({ length: count }, () => 
            ethers.Wallet.createRandom().connect(this.provider)
        );
    }

    static async deployContract(
        name: string, 
        signer: ethers.Wallet,
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

    private static loadArtifact(name: string) {
        const path = join(__dirname, '../../artifacts', `${name}.json`);
        return JSON.parse(readFileSync(path, 'utf8'));
    }
}