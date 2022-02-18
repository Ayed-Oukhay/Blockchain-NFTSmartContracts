/**
 * @type import('hardhat/config').HardhatUserConfig
 */

require('dotenv').config();
require("@nomiclabs/hardhat-ethers");
require("./scripts/deploy.js");
require("./scripts/mint.js");
require("@nomiclabs/hardhat-etherscan");

const { INFURA_KEY, ACCOUNT_PRIVATE_KEY, ETHERSCAN_API_KEY } = process.env;

module.exports = {
  solidity: "0.8.0",
  defaultNetwork: "kovan",
   networks: {
    hardhat: {},
    mumbai: {
      url: `https://kovan.infura.io/v3/${INFURA_KEY}`,
      accounts: [`0x${ACCOUNT_PRIVATE_KEY}`]
    },
    ethereum: {
      chainId: 1,
      url: `https://kovan.infura.io/v3/${INFURA_KEY}`,
      accounts: [`0x${ACCOUNT_PRIVATE_KEY}`]
    },
  },
  etherscan: {
    apiKey: ETHERSCAN_API_KEY,
  },
};
