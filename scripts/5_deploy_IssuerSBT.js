

const hre = require("hardhat");
const { writeAbiAddr } = require('./artifact_log.js');

const TaskAddr = require(`../deployments/${hre.network.name}/DeTask.json`);
const DeOrderAddr = require(`../deployments/${hre.network.name}/DeOrder.json`);
const WETHAddr = require(`../deployments/${hre.network.name}/WETH.json`);
const MetaCommonAddr = require(`../deployments/${hre.network.name}/MetaCommon.json`);


async function main() {
    await hre.run('compile');
    const [owner] = await hre.ethers.getSigners();

    const DeOrderSBTFactory = await hre.ethers.getContractFactory("DeOrderSBT");

    const issuerSBT = await DeOrderSBTFactory.deploy(DeOrderAddr.address, "Detask Issuer SBT", "DIssuer");
    await issuerSBT.deployed();

    let orderSBTArtifact = await artifacts.readArtifact("DeOrderSBT");
    await writeAbiAddr(orderSBTArtifact, issuerSBT.address, "IssuerSBT", network.name);

    console.log(`Please verify: npx hardhat verify ${issuerSBT.address} "${DeOrderAddr.address}" "Detask Issuer SBT" "DIssuer"` );

    const IssuerMetadataFactory = await hre.ethers.getContractFactory("IssuerMetadata");
    const issuerMeta = await IssuerMetadataFactory.deploy(TaskAddr.address, 
        DeOrderAddr.address, MetaCommonAddr.address);
    await issuerMeta.deployed();

    tx = await issuerSBT.setMetaContract(issuerMeta.address);
    await tx.wait();



}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });