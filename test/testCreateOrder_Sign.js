const { network, ethers } = require("hardhat");
const { expect } = require("chai");
const { signPermitStage, signPermitProlongStage } = require("./signPermitStage.js");

const DeOrderAddr = require(`../deployments/${hre.network.name}/DeOrder.json`)
const dUSDTAddr = require(`../deployments/${hre.network.name}/dUSDT.json`)

const DeOrderVerifierAddr = require(`../deployments/${hre.network.name}/DeOrderVerifier.json`)

// const { expectRevert } = require("@openzeppelin/test-helpers");


describe("testCreateOrder&Sign", function () {
  let DeOrder;
  let DeOrderVerifier;
  let account1;
  let account2;
  let orderId;

  beforeEach(async function () {
    const accounts = await ethers.getSigners();
    account1 = accounts[0];
    account2 = accounts[1];
    // account2 = "ffa0bb7d74316bd2583d6302507cf03e395b5810824e6b05e1a72ec0d23a3c79";
    
    console.log("account1:" + account1.address);
    // console.log("account2:" + account2.address);
    console.log("test ==>", accounts);

    DeOrder = await ethers.getContractAt("DeOrder", DeOrderAddr.address, account1);

    DeOrderVerifier = await ethers.getContractAt("DeOrderVerifier", DeOrderVerifierAddr.address, account1);
    
  });

  it("createOrder", async function () {
    let currOrderId = await DeOrder.currOrderId();
    let amount = ethers.utils.parseUnits("1", 6)
    console.log("amount:" + amount)


    let tx =await DeOrder.setSupportToken(dUSDTAddr.address, true);
    tx.wait();
    
    tx = await DeOrder.createOrder(1, 
      account1.address,
      account2.address, 
      dUSDTAddr.address,
      amount);
    
    await tx.wait();

    let receipt = await ethers.provider.getTransactionReceipt(tx.hash);
    console.log("createOrder gasUsed:" , receipt.gasUsed);

    orderId = await DeOrder.currOrderId()
    console.log("orderId:" + orderId)
    // expect(orderId).to.equal(currOrderId + 1 );

  });

  it("signPermitStage", async function () {
    let { chainId } = await ethers.provider.getNetwork();
    let nonce = await DeOrderVerifier.nonces(account2.address, orderId);  // get from  
    console.log("nonce:" + nonce)

    let amount1 = ethers.utils.parseUnits("0.1", 6)
    let amount2 = ethers.utils.parseUnits("0.9", 6);  // parseEther("0.9")

    let amounts = [amount1, amount2]
    let periods = ["0", "36000"] 
    let deadline = "99999999999"

    const sig = await signPermitStage(
      chainId,
      DeOrderVerifierAddr.address,
      account2,
      orderId,
      amounts,
      periods,
      nonce,  
      deadline,
    );

      console.log("sig:", sig);
      let r = '0x' + sig.substring(2).substring(0, 64);
      let s = '0x' + sig.substring(2).substring(64, 128);
      let v = '0x' + sig.substring(2).substring(128, 130);
      
      
    await DeOrder.permitStage(orderId,amounts,periods,nonce, deadline, v, r, s);
    // await DeOrder.permitStage(8,["10000"],["1"],0, "99999999999", v, r, s);
    // let signer = await DeOrder.testPermitStage(orderId,amounts,periods,nonce, deadline, v, r, s);
    // console.log("signer:", signer);

  });


  


});
