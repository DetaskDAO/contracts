

const hre = require("hardhat");
const { writeAbiAddr } = require('./artifact_log.js');

const TaskAddr = require(`../deployments/${hre.network.name}/DeTask.json`);
const DeOrderAddr = require(`../deployments/${hre.network.name}/DeOrder.json`);
const MetaCommonAddr = require(`../deployments/${hre.network.name}/MetaCommon.json`);


async function main() {
    await hre.run('compile');
    const [owner] = await hre.ethers.getSigners();


    const DeOrderSBTFactory = await hre.ethers.getContractFactory("DeOrderSBT");
    const builderSBT = await DeOrderSBTFactory.deploy(DeOrderAddr.address, "Detask Builder SBT", "DBuilder");
    await builderSBT.deployed();
    let orderSBTArtifact = await artifacts.readArtifact("DeOrderSBT");
    await writeAbiAddr(orderSBTArtifact, builderSBT.address, "BuilderSBT", network.name);

    console.log(`Please verify: npx hardhat verify ${builderSBT.address} "${DeOrderAddr.address}" "Detask Builder SBT" "DBuilder"` );

    const BuilderMetadataFactory = await hre.ethers.getContractFactory("BuilderMetadata");
    const builderMeta = await BuilderMetadataFactory.deploy(TaskAddr.address, 
        DeOrderAddr.address, MetaCommonAddr.address);
    await builderMeta.deployed();

    console.log(`Please verify: npx hardhat verify ${builderMeta.address} "${TaskAddr.address}" "${DeOrderAddr.address}" "${MetaCommonAddr.address}"` );

    let tx = await builderSBT.setMetaContract(builderMeta.address);
    await tx.wait();

}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });