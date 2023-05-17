const hre = require("hardhat");
const { writeAbiAddr } = require('./artifact_log.js');

const TaskAddr = require(`../deployments/${hre.network.name}/DeTask.json`);
const MetaCommonAddr = require(`../deployments/${hre.network.name}/MetaCommon.json`);

async function main() {
    await hre.run('compile');

    const [owner] = await hre.ethers.getSigners();

    const TaskMetadata = await hre.ethers.getContractFactory("TaskMetadata");

    // Deploy contract with the correct constructor arguments
    console.log("Order task:", TaskAddr.address);
    const metaData = await TaskMetadata.deploy(TaskAddr.address, MetaCommonAddr.address);
    await metaData.deployed();

    console.log("TaskMetadata deployed to:", metaData.address);

    console.log(`Please verify: npx hardhat verify ${metaData.address} "${TaskAddr.address}" "${MetaCommonAddr.address}"` );

    let artifact = await artifacts.readArtifact("TaskMetadata");
    await writeAbiAddr(artifact, metaData.address, "TaskMetadata", network.name);

    const task = await hre.ethers.getContractAt("DeTask", TaskAddr.address);
    const tx = await task.setMetaContract(metaData.address);
    await tx.wait();
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });