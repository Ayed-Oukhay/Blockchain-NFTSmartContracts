//importing the dependencies we installed earlier
var web3 = require('@solana/web3.js');
var splToken = require('@solana/spl-token');

(async () => {createMin
    

// Connect to cluster
var connection = new web3.Connection(
    "https://api.devnet.solana.com",
    'confirmed',
);

// Generate a new wallet keypair and airdrop SOL
var fromWallet = web3.Keypair.generate(); //Creating a new pair of public and secret keys 
var fromAirdropSignature = await connection.requestAirdrop( //takes a public Key, and the amount of lamports (which are are Solana's equivalent to wei, the smallest amount that a SOL can be broken into) in SOL you would like to receive.
    fromWallet.publicKey,
    web3.LAMPORTS_PER_SOL,
);
//wait for airdrop confirmation
await connection.confirmTransaction(fromAirdropSignature);

//create new token mint
let mint = await splToken.Token.createMint(
    connection,
    fromWallet,
    fromWallet.publicKey,
    null,
    9, //Amount of decimal places for your token. Most Solana tokens have 9 decimal places. 
    splToken.TOKEN_PROGRAM_ID, //This creates or fetches the account (mint) associated with the public key (fromWallet.publicKey).
  );

//get the token account of the fromWallet Solana address, if it does not exist, create it
let fromTokenAccount = await mint.getOrCreateAssociatedAccountInfo(
    fromWallet.publicKey,
);

// Generate a new wallet to receive newly minted token
var toWallet = web3.Keypair.generate();

//get the token account of the toWallet Solana address, if it does not exist, create it
var toTokenAccount = await mint.getOrCreateAssociatedAccountInfo(
    toWallet.publicKey,
  );

//minting 1 new token to the "fromTokenAccount" account we just returned/created
await mint.mintTo(
    fromTokenAccount.address, //destination: who it goes to
    fromWallet.publicKey, // minting authority
    [], // multisig: This is where you would pass multiple signer's addresses if you had set up your token to have multi-signature functionality. We did not in our case, so we pass an empty array. ([]) 
    1000000000, // how many tokens to send. Since we have 9 decimal places in this particular token, we are sending exactly 1 token to the address
  );

await mint.setAuthority( //This will revoke minting privileges and ensure that we can not create additional tokens of this type (This action can not be undone)
    mint.publicKey, //account of the token
    null, //new authority you want to set.
    "MintTokens", //type of authority that the account currently has
    fromWallet.publicKey, //public key of the current authority holder.
    [] //array of signers
)

// Add token transfer instructions to transaction
var transaction = new web3.Transaction().add(
    splToken.Token.createTransferInstruction(
      splToken.TOKEN_PROGRAM_ID,
      fromTokenAccount.address,
      toTokenAccount.address,
      fromWallet.publicKey,
      [],
      1,
    ),
  );

// Sign transaction, broadcast, and confirm
var signature = await web3.sendAndConfirmTransaction(
    connection,
    transaction,
    [fromWallet],
    {commitment: 'confirmed'},
  );
  console.log('SIGNATURE', signature);

})().catch( e => { console.error(e) });