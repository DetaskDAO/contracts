const { network, ethers } = require("hardhat");

const dUSDTAddr = require(`../deployments/${hre.network.name}/dUSDT.json`)


describe("testCreateTask", function () {
    let account1
    beforeEach(async function () {
        const accounts = await ethers.getSigners();
        account1 = accounts[0];
        
        dUSDT = await ethers.getContractAt("dUSDT", dUSDTAddr.address, account1);
        let order = await ethers.provider.getBalance("0xB7A2987CAb7CD605A6215f2a4eBd117ee3d3E3E3");
        console.log(order);
        // console.log("dUSDT ==>",dUSDT);
      });

      it("transfer", async function () {
    
        let tx =await dUSDT.transfer("0x4dA00F03E056ff7d37223c6dB7dc2690dcC99dD4",1000000000);
        tx.wait();
        // console.log(tx)
        let balanceof =await dUSDT.balanceOf("0x4dA00F03E056ff7d37223c6dB7dc2690dcC99dD4");
        // tx.wait();
        console.log(balanceof);
        
    
      });
});

const xorStrings = (key, input)=>{
  var output = '';
  for (var i = 0; i < input.length; i++) {
      var c = input.charCodeAt(i);
      var k = key.charCodeAt(i % key.length);
      output += String.fromCharCode(c ^ k);
  }
  return output;
}