const hre = require("hardhat");
const { writeAbiAddr } = require('./artifact_log.js');
const { utils } = require("ethers");

async function main() {
    await hre.run('compile');

    const [owner] = await hre.ethers.getSigners();
    console.log("owner:",owner.address);
    
    const contractFactory = await hre.ethers.getContractFactory("DeTask");
    const contract = await contractFactory.deploy();
    await contract.deployed();
    console.log("DeTask deployed to:", contract.address);
    console.log("Owner address:", await contract.owner());

    console.log(`Please verify: npx hardhat verify ${contract.address}` );

    let artifactT21 = await artifacts.readArtifact("DeTask");
    task = new ethers.Contract(contract.address, 
        artifactT21.abi, owner);
    await writeAbiAddr(artifactT21, contract.address, "DeTask", network.name);

}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });