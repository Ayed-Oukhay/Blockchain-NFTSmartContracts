var NFT_SC = artifacts.require("../contracts/TRON_NFT.sol")

module.exports = function(deployer) {
  deployer.deploy(NFT_SC);
};
