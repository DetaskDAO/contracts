const hre = require("hardhat");
const { writeAbiAddr } = require('./artifact_log.js');
const { utils } = require("ethers");

async function main() {
    await hre.run('compile');
    const [deployer] = await hre.ethers.getSigners();

    const Hello = await hre.ethers.getContractFactory("Hello");
    // Deploy contract with the correct constructor arguments
    const h = await Hello.deploy();
    await h.deployed();
    // Get contract address
    console.log("Hello deployed to:", h.address);

    let artifact = await artifacts.readArtifact("Hello");
    await writeAbiAddr(artifact, h.address, "Hello", network.name);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });