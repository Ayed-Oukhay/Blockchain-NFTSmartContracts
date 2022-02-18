const { expect } = require("chai");
//const { ethers } = require("hardhat"); //The ethers variable is available in the global scope but if you like your code always being explicit, you can add this line

describe("Token contract", function () {
    
  it("Deployment should assign the total supply of tokens to the owner", async function () {
    const [owner] = await ethers.getSigners(); //an object that represents an Ethereum account used to send transactions to contracts and other accounts.

    const Token = await ethers.getContractFactory("NFT"); //an abstraction used to deploy new smart contracts, so Token here is a factory for instances of our token contract.

    const hardhatToken = await Token.deploy(); //This will start the deployment, and return a Promise that resolves to a Contract. This is the object that has a method for each of your smart contract functions.

    const ownerBalance = await hardhatToken.balanceOf(owner.address); //Used to get the balance of the owner account
    expect(await hardhatToken.totalSupply()).to.equal(ownerBalance); 
  });
  
});