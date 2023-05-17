const hre = require("hardhat");
const { writeAbiAddr } = require('./artifact_log.js');
const { utils } = require("ethers");

async function main() {
    await hre.run('compile');

    const [owner] = await hre.ethers.getSigners();
    console.log("owner:",owner.address);
    
    const dUSDT = await hre.ethers.getContractFactory("dUSDT");
    const contract = await dUSDT.deploy();
    await contract.deployed();
    console.log("dUSDT deployed to:", contract.address);

    let artifact = await artifacts.readArtifact("dUSDT");
    await writeAbiAddr(artifact, contract.address, "USDT", network.name);

}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });