const { ethers, network } = require("hardhat");
const { expect } = require("chai");
const { signPermitStage, signPermitProlongStage } = require("./signPermitStage.js");

const DeOrderAddr = require(`../deployments/${network.name}/DeOrder.json`)
const DeOrderVerifierAddr = require(`../deployments/${hre.network.name}/DeOrderVerifier.json`)
const WETHAddr = require(`../deployments/${network.name}/WETH.json`)
const dUSDTAddr = require(`../deployments/${hre.network.name}/dUSDT.json`)

/** 
 * Test Case：
 * 0. Test phase amount does not match payment amount (verified)
 * 1. Test not paid
 * 2. Test for overpayment and withdraw excess amount
 * 3. 
 * 4. 
 */

// run testCreateOrder_Sign
describe("testStartOrder", function () {
  let DeOrder;
  let DeOrderVerifier;
  let account1;
  let account2;
  let orderId;
  let weth;

  beforeEach(async function () {
    const accounts = await ethers.getSigners();
    account1 = accounts[0];
    account2 = accounts[1];
    
    console.log("account1:" + account1.address);
    console.log("account2:" + account2.address);

    DeOrder = await ethers.getContractAt("DeOrder", DeOrderAddr.address, account1);
    DeOrderVerifier = await ethers.getContractAt("DeOrderVerifier", DeOrderVerifierAddr.address, account1);

    weth = await ethers.getContractAt("WETH", WETHAddr.address, account1);
    dUSDT = await ethers.getContractAt("dUSDT", dUSDTAddr.address, account1);

    orderId = await DeOrder.currOrderId()
    console.log("orderId:" + orderId)

  });


  it("not pay should cannot start order ", async function () {
    await expect(DeOrder.startOrder(orderId)).to.be.revertedWith('AmountError(1)');
  });

  it("pay start order", async function () {
    let amount = ethers.utils.parseUnits("1", 6)

    let ab = await dUSDT.balanceOf(account1.address)
    console.log("dUSDT balance:", ab.toString())

    let tx
    tx = await dUSDT.approve(DeOrder.address, amount);
    await tx.wait();

    let allowanced  = await dUSDT.allowance(account1.address, DeOrder.address);
    console.log("dUSDT allowanced:", allowanced.toString())

    try {
      let tx = await DeOrder.payOrder(orderId, amount, {value: 0});
      await tx.wait();
    } catch (error) {
      console.log("payOrder error", error)
    }


    let b = await weth.balanceOf(DeOrder.address);
    console.log("weth balance:", b.toString())

    b = await dUSDT.balanceOf(DeOrder.address)
    console.log("dUSDT balance:", b.toString())

    let order = await DeOrder.getOrder(orderId);
    console.log("order.token", order.token)
    console.log("order.amount", order.amount.toString())
    console.log("order.payed", order.payed.toString())

    tx = await DeOrder.startOrder(orderId);
    await tx.wait();

    let receipt = await ethers.provider.getTransactionReceipt(tx.hash);
    console.log("startOrder gasUsed" , receipt.gasUsed);

  });

  it("signPermitProlongStage", async function () {
    let { chainId } = await ethers.provider.getNetwork();
    let nonce = await DeOrderVerifier.nonces(account2.address, orderId);  // get from  
    console.log("nonce:" + nonce)

    let period = "36000" 
    let deadline = "99999999999"

    const sig = await signPermitProlongStage(
      chainId,
      DeOrderVerifierAddr.address,
      account2,
      orderId,
      1,
      period,
      nonce,  
      deadline,
    );

      console.log("sig:", sig);
      let r = '0x' + sig.substring(2).substring(0, 64);
      let s = '0x' + sig.substring(2).substring(64, 128);
      let v = '0x' + sig.substring(2).substring(128, 130);
      
      
    let tx = await DeOrder.prolongStage(orderId, 1 , period, nonce, deadline, v, r, s);
    console.log("prolongStage OK ");

  });
});
