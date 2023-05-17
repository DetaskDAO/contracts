const { ethers, network } = require("hardhat");
const { expect } = require("chai");

const { getBalance } =  require("./../scripts/utils/block")

const DeOrderAddr = require(`../deployments/${network.name}/DeOrder.json`)
const DeStageAddr = require(`../deployments/${network.name}/DeStage.json`)
const IssuerSBTAddr = require(`../deployments/${network.name}/IssuerSBT.json`)
const BuilderSBTAddr = require(`../deployments/${network.name}/BuilderSBT.json`)

/** 
 * Test Case：
 * 0. Test phase amount does not match payment amount (verified)
 * 1. Test not paid
 * 2. Test for overpayment and withdraw excess amount
 * 3. 
 * 4. 
 */

// run testCreateOrder_Sign
describe("testWithdraw", function () {
  let DeOrder;
  let account1;
  let account2;
  let orderId;

  let IssuerSBT;
  let BuilderSBT;

  beforeEach(async function () {
    const accounts = await ethers.getSigners();
    account1 = accounts[0];
    account2 = accounts[1];
    
    console.log("account1:" + account1.address);
    console.log("account2:" + account2.address);

    DeOrder = await ethers.getContractAt("DeOrder", DeOrderAddr.address, account2);
    orderId = await DeOrder.currOrderId()
    console.log("orderId:" + orderId)

    DeStage = await ethers.getContractAt("DeStage", DeStageAddr.address, account2);


    IssuerSBT = await ethers.getContractAt("DeOrderSBT", IssuerSBTAddr.address, account2);
    BuilderSBT = await ethers.getContractAt("DeOrderSBT", BuilderSBTAddr.address, account2);

  });


  // it("test confirm Delivery" , async function (){
  //   let tx = await DeOrder.confirmDelivery(orderId, [0, 1]); 
  //   await tx.wait()
  //   console.log("confirmDelivery OK ");
  // })

  it("Withdraw", async function () {
    let pending = await DeStage.pendingWithdraw(orderId);
    console.log("pending:", ethers.utils.formatUnits(pending[0]));

    let user2b1 = await getBalance(account2.address)
    console.log("Withdraw before :", user2b1);

    tx = await DeOrder.withdraw(orderId, account2.address);
    await tx.wait();

    let user2b2 = await getBalance(account2.address)
    console.log("Withdraw after:", user2b2);

  });


  it("SBT", async function () {
    let tokenURI = await BuilderSBT.tokenURI(orderId);
    // console.log("Builder tokenURI:", tokenURI);

    tokenURI = await IssuerSBT.tokenURI(orderId)
    // console.log("IssuerSBT tokenURI:", tokenURI);

  });





});