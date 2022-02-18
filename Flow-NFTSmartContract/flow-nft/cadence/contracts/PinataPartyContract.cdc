pub contract PinataPartyContract {

  pub resource NFT {
    // Resources are items stored in user accounts and accessible through access control measures.
    pub let id: UInt64
    init(initID: UInt64) {
      self.id = initID
    }
  }

  pub resource interface NFTReceiver {
    // This NFTReceiver resource interface is saying that whoever we define as having access to the resource will be able to call the following methods: *deposit *getIDs *idExists *getMetadata
    //Theses are the functions that will be PUBLICLY ACCESSIBLE to anyone
    pub fun deposit(token: @NFT, metadata: {String : String})
    pub fun getIDs(): [UInt64]
    pub fun idExists(id: UInt64): Bool
    pub fun getMetadata(id: UInt64) : {String : String}
  }

  // Defining our token collection interface (Think of this as the wallet that houses all a user’s NFT)
  pub resource Collection: NFTReceiver {
    pub var ownedNFTs: @{UInt64: NFT} //keeps track of all the NFTs a user owns from this contract
    pub var metadataObjs: {UInt64: { String : String }} //maps a token id to its associated metadata

    // initializing our variables
    init () {
        self.ownedNFTs <- {}
        self.metadataObjs = {}
    }

    pub fun withdraw(withdrawID: UInt64): @NFT {
        let token <- self.ownedNFTs.remove(key: withdrawID)!

        return <-token
    }

    pub fun deposit(token: @NFT, metadata: {String : String}) {
        //This method includes the metadataObjs mapping, because we need to make sure that only the minter of the token can add that metadata to the token.
        //To keep this private, we keep the initial addition of the metadata confined to the minting execution.
        self.metadataObjs[token.id] = metadata
        self.ownedNFTs[token.id] <-! token
    }

    pub fun idExists(id: UInt64): Bool {
        return self.ownedNFTs[id] != nil
    }

    pub fun getIDs(): [UInt64] {
        return self.ownedNFTs.keys
    }

    pub fun updateMetadata(id: UInt64, metadata: {String: String}) {
        self.metadataObjs[id] = metadata
    }

    pub fun getMetadata(id: UInt64): {String : String} {
        return self.metadataObjs[id]!
    }

    destroy() {
        destroy self.ownedNFTs
    }
  }
    
  pub fun createEmptyCollection(): @Collection { //creates an empty NFT collection when called
    //This is how a user who is first interacting with our contract will have a storage location created that maps to the Collection resource we defined.
    return <- create Collection()
  }
  
  pub resource NFTMinter { //Without this resource we can't mint tokens
    pub var idCount: UInt64  //incremented to ensure we never have duplicate ids for our NFTs

    init() {
        self.idCount = 1
    }

    pub fun mintNFT(): @NFT {
        var newNFT <- create NFT(initID: self.idCount)
        self.idCount = self.idCount + 1 as UInt64
        return <- newNFT
    }
  }

  //The main contract initializer, called only when the contract is deployed
  init() {
    self.account.save(<-self.createEmptyCollection(), to: /storage/NFTCollection) //Creates an empty Collection for the deployer of the collection so that the owner of the contract can mint and own NFTs from that contract.
    self.account.link<&{NFTReceiver}>(/public/NFTReceiver, target: /storage/NFTCollection) //This is how we tell the contract that the functions defined on the NFTReceiver can be called by anyone.
    self.account.save(<-create NFTMinter(), to: /storage/NFTMinter) //This means only the creator of the contract can mint tokens.
  }
}