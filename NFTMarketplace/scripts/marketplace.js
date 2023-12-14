const { ethers } = require('ethers');
const nftMarketplaceAbi = require('./NFTMarketplace.json'); 
const contractAddress = '0xcbfdd8ad3bd67b85ccc96c049085170f71b473f6'; // Deployed contract address

// Configure your provider (Infura, Alchemy, etc.)
const provider = new ethers.providers.JsonRpcProvider('YOUR_PROVIDER_URL');

// Replace with the private key for the wallet you want to use to interact with the contract
const privateKey = 'YOUR_PRIVATE_KEY';
const wallet = new ethers.Wallet(privateKey, provider);

// Creating an instance of your contract
const nftMarketplaceContract = new ethers.Contract(contractAddress, nftMarketplaceAbi, wallet);

// Function to list an NFT for a fixed price
async function listFixedPrice(tokenId, price) {
    const transaction = await nftMarketplaceContract.listFixedPrice(tokenId, ethers.utils.parseEther(price.toString()));
    await transaction.wait();
    console.log(`NFT with token ID ${tokenId} listed for ${price} ETH`);
}

// Function to buy a fixed price NFT
async function buyFixedPrice(tokenId, price) {
    const transaction = await nftMarketplaceContract.buyFixedPrice(tokenId, { value: ethers.utils.parseEther(price.toString()) });
    await transaction.wait();
    console.log(`NFT with token ID ${tokenId} bought for ${price} ETH`);
}

// Function to create an auction
async function createAuction(tokenId, startingPrice, duration) {
    const transaction = await nftMarketplaceContract.createAuction(tokenId, ethers.utils.parseEther(startingPrice.toString()), duration);
    await transaction.wait();
    console.log(`Auction for NFT with token ID ${tokenId} created with starting price ${startingPrice} ETH`);
}

// Function to place a bid in an auction
async function placeBid(tokenId, bidAmount) {
    const transaction = await nftMarketplaceContract.placeBid(tokenId, { value: ethers.utils.parseEther(bidAmount.toString()) });
    await transaction.wait();
    console.log(`Bid of ${bidAmount} ETH placed for NFT with token ID ${tokenId}`);
}

// Function to get all bidders for an auction
async function getAllBidders(tokenId) {
    const bidders = await nftMarketplaceContract.getAllBidders(tokenId);
    console.log(`Bidders for the NFT with token ID ${tokenId}:`, bidders);
}

// Function to get auction details
async function getAuctionListing(tokenId) {
    const auctionDetails = await nftMarketplaceContract.getAuctionListing(tokenId);
    console.log(`Auction details for NFT with token ID ${tokenId}:`, auctionDetails);
}

// Example usage
(async () => {
    try {
        // Replace with actual token IDs and values for testing
        // await listFixedPrice(1, 1); // Token ID 1, Price 1 ETH
        // await buyFixedPrice(1, 1); // Token ID 1, Price 1 ETH
        // await createAuction(2, 0.5, 3600); // Token ID 2, Starting Price 0.5 ETH, Duration 1 hour
        // await placeBid(2, 0.6); // Token ID 2, Bid 0.6 ETH
        // await getAllBidders(2); // Token ID 2
        // await getAuctionListing(2); // Token ID 2
    } catch (error) {
        console.error("Error:", error);
    }
})();
