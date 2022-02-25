import PinataPartyContract from 0xf8d6e0586b0a20c7 //importing our contract from the deployed address.

pub fun main() : {String : String} { //required function name for a script to run
    let nftOwner = getAccount(0xf8d6e0586b0a20c7) //This is simply the account that owns the NFT.
    /* We minted the NFT from the account that also deployed the contract, so in our example those two addresses are the same. 
    That may not always be true depending on the design of your contracts in the future */
    // log("NFT Owner")    
    let capability = nftOwner.getCapability<&{PinataPartyContract.NFTReceiver}>(/public/NFTReceiver) //We need to “borrow” the available capabilities (or functions) from the deployed contract.

    let receiverRef = capability.borrow() //This variable simply takes our capability and tells the script to borrow from the deployed contract.
        ?? panic("Could not borrow the receiver reference")

    return receiverRef.getMetadata(id: 1) //Returns the metadata associated to our created token
}