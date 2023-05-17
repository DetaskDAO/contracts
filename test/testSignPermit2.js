const { ethers, network } = require("hardhat");
const { expect } = require("chai");
const { signPermit2 } = require("./signPermit2.js");

const dUSDTAddr = require(`../deployments/${network.name}/dUSDT.json`)
const DeOrderAddr = require(`../deployments/${network.name}/DeOrder.json`)
const permit2Addr = "0xd5fcbca53263fcac0a98f0231ad9361f1481692b";

/** 
 * Test Case：
 * 0. Test phase amount does not match payment amount (verified)
 * 1. Test not paid
 * 2. Test for overpayment and withdraw excess amount
 * 3. 
 * 4. 
 */

describe("testStartOrder", function () {
    let account1;
    let account2;
    let Permi2;
    let mToken;
    let DeOrder;
    beforeEach(async function () {
        const accounts = await ethers.getSigners();
        account1 = accounts[0];
        account2 = { address: "0x8ba1f109551bd432803012645ac136ddd64dba72" };

        console.log("account1:" + account1.address);
        console.log("account2:" + account2.address);

        Permi2 = await ethers.getContractAt("IPermit2", permit2Addr, account1);
        DeOrder = await ethers.getContractAt("DeOrder", DeOrderAddr.address, account1);

        mToken = await ethers.getContractAt("dUSDT", dUSDTAddr.address, account1);
        let tx = await mToken.approve(permit2Addr, ethers.constants.MaxUint256); // approve
        await tx.wait();
        let txCreate = await DeOrder.createOrder(1, account1.address, account2.address, dUSDTAddr.address, 1);// create order
        await txCreate.wait();
        // console.log("Permi2:" + Permi2)

    });

    it("signPermit2", async function () {
        let { chainId } = await ethers.provider.getNetwork();
        let nonce = 999;
        console.log("nonce:" + nonce + ", chainId: " + chainId);

        let deadline = "2672910607"
        let spender = DeOrder.address
        let token = dUSDTAddr.address

        const sig = await signPermit2(
            chainId,
            permit2Addr,
            account1,
            token,
            1,
            spender,
            nonce,
            deadline,
        );

        console.log("sig:", sig);
        //   let r = '0x' + sig.substring(2).substring(0, 64);
        //   let s = '0x' + sig.substring(2).substring(64, 128);
        //   let v = '0x' + sig.substring(2).substring(128, 130);
        let orderId = await DeOrder.currOrderId();
        console.log(orderId);
        let amount = 1;

        let tx = await DeOrder.payOrderWithPermit2(
            orderId,
            amount,
            {
                permitted: {
                    token: token,
                    amount: 1
                },
                nonce: nonce,
                deadline: deadline
            },
            sig
        )
        await tx.wait();
        console.log(tx);


    });

});
