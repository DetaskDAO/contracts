const hre = require("hardhat");
const { writeAbiAddr } = require('./artifact_log.js');

const TaskAddr = require(`../deployments/${hre.network.name}/DeTask.json`);

async function main() {
    await hre.run('compile');

    const [owner] = await hre.ethers.getSigners();

    const MetaCommon = await hre.ethers.getContractFactory("MetaCommon");
    const common = await MetaCommon.deploy();
    await common.deployed();

    

    let MetaArtifact = await artifacts.readArtifact("MetaCommon");
    await writeAbiAddr(MetaArtifact, common.address, "MetaCommon", network.name);

    console.log(`Please verify: npx hardhat verify ${common.address} ` );
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });