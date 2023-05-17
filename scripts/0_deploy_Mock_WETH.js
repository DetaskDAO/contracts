const hre = require("hardhat");
const { writeAbiAddr } = require('./artifact_log.js');
const { utils } = require("ethers");

async function main() {
    await hre.run('compile');

    const [owner] = await hre.ethers.getSigners();
    console.log("owner:",owner.address);
    
    const WETH = await hre.ethers.getContractFactory("WETH");
    const contract = await WETH.deploy();
    await contract.deployed();
    console.log("WETH deployed to:", contract.address);

    let artifact = await artifacts.readArtifact("WETH");
    await writeAbiAddr(artifact, contract.address, "WETH", network.name);

}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });