const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NFTMarketplace", function () {
    let NFTMarketplace;
    let nftMarketplace;
    let owner;
    let addr1;
    let addr2;
    let addrs;

    beforeEach(async function () {
        NFTMarketplace = await ethers.getContractFactory("NFTMarketplace");
        [owner, addr1, addr2, ...addrs] = await ethers.getSigners();

        nftMarketplace = await NFTMarketplace.deploy();
        await nftMarketplace.deployed();
    });

    describe("Minting NFTs", function () {
        it("Should mint an NFT to addr1", async function () {
            await nftMarketplace.connect(owner).mint(addr1.address, 1);
            expect(await nftMarketplace.ownerOf(1)).to.equal(addr1.address);
        });
    });

    describe("Listing NFTs for fixed price", function () {
        it("Should list and sell an NFT at a fixed price", async function () {
            // Mint NFT to addr1
            await nftMarketplace.connect(owner).mint(addr1.address, 1);

            // List NFT for sale by addr1
            const listingPrice = ethers.utils.parseEther("1.0"); // 1 ETH
            await nftMarketplace.connect(addr1).listFixedPrice(1, listingPrice);

            // Buy NFT with addr2
            await nftMarketplace.connect(addr2).buyFixedPrice(1, { value: listingPrice });
            expect(await nftMarketplace.ownerOf(1)).to.equal(addr2.address);
        });
    });

    describe("Creating and bidding in auctions", function () {
        it("Should create an auction and accept bids", async function () {
            // Mint NFT to addr1
            await nftMarketplace.connect(owner).mint(addr1.address, 1);

            // Create an auction
            const startingPrice = ethers.utils.parseEther("0.5"); // 0.5 ETH
            const duration = 86400; // 1 day in seconds
            await nftMarketplace.connect(addr1).createAuction(1, startingPrice, duration);

            // Place a bid by addr2
            const bidAmount = ethers.utils.parseEther("0.6");
            await nftMarketplace.connect(addr2).placeBid(1, { value: bidAmount });

            // Check highest bid
            const auction = await nftMarketplace.getAuctionListing(1);
            expect(auction.highestBid).to.equal(bidAmount);
            expect(auction.highestBidder).to.equal(addr2.address);
        });
    });

    // Additional tests for other functionalities...
});
