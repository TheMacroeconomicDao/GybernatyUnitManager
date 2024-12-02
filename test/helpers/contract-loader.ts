import { ethers } from 'ethers';
import { readFileSync } from 'fs';
import { join } from 'path';

export class ContractLoader {
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