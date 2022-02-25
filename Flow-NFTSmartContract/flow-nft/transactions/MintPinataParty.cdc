import PinataPartyContract from 0xf8d6e0586b0a20c7 // This is the account @ given to us after deploying our contract

// Defining the transaction
transaction {
  let receiverRef: &{PinataPartyContract.NFTReceiver}
  let minterRef: &PinataPartyContract.NFTMinter
  // In this case we are both the receiver of the NFT and the minter of the NFT

  prepare(acct: AuthAccount) { // This takes the account information of the person trying to execute the transaction and does some validations.
      self.receiverRef = acct.getCapability<&{PinataPartyContract.NFTReceiver}>(/public/NFTReceiver)
          .borrow()
          ?? panic("Could not borrow receiver reference")        
      
      self.minterRef = acct.borrow<&PinataPartyContract.NFTMinter>(from: /storage/NFTMinter)
          ?? panic("could not borrow minter reference")
  }
  //This function is where we build up the metadata for our NFT, mint the NFT, then associate the metadata prior to depositing the NFT in our account. 
  execute {
      let metadata : {String : String} = {
          "name": "Noiiice",
          "meme-year": "2018",  
          "rating": "7/10",
          "uri": "ipfs://QmSnMSBBVLfTh7beSJ2Q2PsLSsKvgdfQ4JkmZLbQHHXiJC" //This hash is the CID provided for us after uploading our file into Pinata
      }
      let newNFT <- self.minterRef.mintNFT() //This will create our token
  
      self.receiverRef.deposit(token: <-newNFT, metadata: metadata) //This puts the token into our account and this is also where we pass in the metadata.

      log("NFT Minted and deposited to Account 2's Collection")
  }
}