const { expect } = require("chai");
const { ethers } = require("hardhat");

let detask;
let accounts = [];
let owner;
let metaData

const testHash = `QmSsw6EcnwEiTT9c4rnAGeSENvsJMepNHmbrgi2S9bXNJr`;

async function init() {
    accounts = await ethers.getSigners();
    owner = accounts[0];

    // DeTask
    const DeTask = await ethers.getContractFactory("DeTask");
    detask = await DeTask.deploy();
    await detask.deployed();
    console.log("detask:" + detask.address);

    const MetaCommon = await hre.ethers.getContractFactory("MetaCommon");
    const common = await MetaCommon.deploy();
    await common.deployed();

    const TaskMetadata = await hre.ethers.getContractFactory("TaskMetadata");
    metaData = await TaskMetadata.deploy(detask.address, common.address );
    await metaData.deployed();

    console.log("metaAddr:" + metaData.address);

    const tx = await detask.setMetaContract(metaData.address);
    await tx.wait();
}

function tokenAmount(value) {
    let tokenAmount = ethers.utils.parseEther(value);
    return tokenAmount.toString();
}

describe("detask", function() {
    before(async function () {
        await init();
    });

    it("createTask", async function(){
        console.log("createTask")
        const tx = await detask.createTask(
            accounts[1].address,
        { 
            title: "new task",
            desc: "QmSsw6EcnwEiTT9c4rnAGeSENvsJMepNHmbrgi2S9bXNJr",
            attachment: "QmSsw6EcnwEiTT9c4rnAGeSENvsJMepNHmbrgi2S9bXNJr",
            currency: 2,
            budget: ethers.utils.parseEther("11.23"),
            period: 123213,
            skills: "50331650" , // 1, 2, 3,
            timestamp: 123213,
            disabled: false
        },
        {
            value: ethers.utils.parseEther("1")
        }
        );

        await tx.wait();

        // const taskInfo = await detask.tasks(1);
        // console.log(taskInfo)

        const svg = await metaData.tokenURI(1);
        console.log("SVG");
        console.log(svg);

    });

});
