

const hre = require("hardhat");
const { writeAbiAddr } = require('./artifact_log.js');

const TaskAddr = require(`../deployments/${hre.network.name}/DeTask.json`);
const WETHAddr = require(`../deployments/${hre.network.name}/WETH.json`);
const USDCAddr = require(`../deployments/${hre.network.name}/USDC.json`);
const USDTAddr = require(`../deployments/${hre.network.name}/USDT.json`);
const Permit2Addr = require(`../deployments/${hre.network.name}/Permit2.json`);
const MetaCommonAddr = require(`../deployments/${hre.network.name}/MetaCommon.json`);


async function main() {
    await hre.run('compile');
    const [owner] = await hre.ethers.getSigners();

    const contractFactory = await hre.ethers.getContractFactory("DeOrder");

    // polygon
    const order = await contractFactory.deploy(WETHAddr.address, Permit2Addr.address);

    await order.deployed();
    console.log("DeOrder deployed to:", order.address);
    
    let artifact = await artifacts.readArtifact("DeOrder");
    await writeAbiAddr(artifact, order.address, "DeOrder", network.name);

    console.log(`Please verify: npx hardhat verify ${order.address} "${WETHAddr.address}" "${Permit2Addr.address}"` );

    tx = await order.setSupportToken(USDTAddr.address,true);
    await tx.wait();
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });