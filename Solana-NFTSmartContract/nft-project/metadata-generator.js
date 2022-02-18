const fs = require('fs');

const imageDir = fs.readdirSync("./assets");

imageDir.forEach (img => {
  const metadata = {
    name: `Image ${img.split(".")[0]}`,
    description: "An image in the NFT collection",
    image: img,
    properties: {
      files: [{ uri: img, "type": "image/png" }],
      category: "image",
      creators: [{
        address: "YOUR_SOL_WALLET_ADDRESS",
        share: 100
      }]
    }
  }
  fs.writeFileSync(`./assets/${img.split(".")[0]}`, JSON.stringify(metadata))
});