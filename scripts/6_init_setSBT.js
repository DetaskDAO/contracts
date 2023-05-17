
const hre = require("hardhat");
const { writeAbiAddr } = require('./artifact_log.js');

const DeOrderAddr = require(`../deployments/${hre.network.name}/DeOrder.json`);
const BuilderSBTAddr = require(`../deployments/${hre.network.name}/BuilderSBT.json`);
const IssuerSBTAddr = require(`../deployments/${hre.network.name}/IssuerSBT.json`);


async function main() {
    const order = await hre.ethers.getContractAt("DeOrder", DeOrderAddr.address);
    tx = await order.setSBT(BuilderSBTAddr.address, IssuerSBTAddr.address);
    await tx.wait();
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });