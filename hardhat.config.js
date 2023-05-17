require("@nomiclabs/hardhat-waffle");
// npx hardhat size-contracts
require('hardhat-contract-sizer');
require("@nomiclabs/hardhat-etherscan");

let dotenv = require('dotenv')
dotenv.config({ path: "./.env" })

const mnemonic = process.env.MNEMONIC
const infurakey = process.env.INFURA_API_KEY
const scankey = process.env.ETHERSCAN_API_KEY

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    version: "0.8.17",
    settings: {
      viaIR: true,
      optimizer: {
        enabled: true,
        runs: 10000,
      },
    },
  },
  networks: {
    localdev: {
      url: "http://127.0.0.1:8545",
      chainId: 31337,
      gas: 12000000,
    },
    ropsten: {
      url: `https://ropsten.infura.io/v3/${infurakey}`,
      accounts: {
        mnemonic: mnemonic,
      },
      chainId: 3,
    },
    polygon: {
      url: "https://polygon.llamarpc.com",
      accounts: {
        mnemonic: mnemonic,
      },
      chainId: 137,
    }
  },

  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://etherscan.io/
    apiKey: scankey
},
};
