const hre = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  // Deploy UserManager
  const UserManager = await ethers.getContractFactory("UserManager");
  const userManager = await UserManager.deploy();
  await userManager.waitForDeployment();
  console.log("UserManager deployed to:", await userManager.getAddress());

  // Deploy TokenManager with example level limits
  const levelLimits = [1000, 2000, 3000, 4000]; // Example limits for levels 1-4
  const TokenManager = await ethers.getContractFactory("TokenManager");
  const tokenManager = await TokenManager.deploy(
    "0x1234567890123456789012345678901234567890", // Replace with actual GBR token address
    await userManager.getAddress(),
    levelLimits
  );
  await tokenManager.waitForDeployment();
  console.log("TokenManager deployed to:", await tokenManager.getAddress());
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });