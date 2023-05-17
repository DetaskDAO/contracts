const { network, ethers } = require("hardhat");

const DeTaskAddr = require(`../deployments/${hre.network.name}/DeTask.json`)


describe("testCreateTask", function () {

    let DeTask;
    let account1;
    let account2;

    let taskId;

    beforeEach(async function () {
        const accounts = await ethers.getSigners();
        account1 = accounts[0];
        account2 = accounts[1];

        console.log("account1:" + account1.address);
        console.log("account2:" + account2.address);
    
        DeTask = await ethers.getContractAt("DeTask", DeTaskAddr.address, account1);


    })

    it("createTask", async function () {
        const tx = await DeTask.createTask(
            account1.address,
        { 
            title: "Create SBT on Polygon",
            desc: "QmSsw6EcnwEiTT9c4rnAGeSENvsJMepNHmbrgi2S9bXNJr",
            attachment: "QmSsw6EcnwEiTT9c4rnAGeSENvsJMepNHmbrgi2S9bXNJr",
            currency: 2,
            budget: ethers.utils.parseEther("9.23"),
            period: 123213,
            skills: "16781315" , // 1, 2, 3,
            timestamp: 123213,
            disabled: false
        },
        {
            value: ethers.utils.parseEther("1")
        }
        );

        await tx.wait();

        const uri = await DeTask.tokenURI(1);
        console.log("detask tokenURI:", uri);


        let receipt = await ethers.provider.getTransactionReceipt(tx.hash);
        console.log("createTask gasUsed" , receipt.gasUsed);


    })

});