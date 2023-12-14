// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract NFTMarketplace is
    Initializable,
    ERC721Upgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    struct FixedPriceListing {
        uint256 price;
        address seller;
        bool active;
    }

    mapping(uint256 => FixedPriceListing) public fixedPriceListings;

    event ItemListed(
        uint256 indexed tokenId,
        address indexed seller,
        uint256 price
    );
    event ItemSold(
        uint256 indexed tokenId,
        address indexed seller,
        address indexed buyer,
        uint256 price
    );
    event ItemDelisted(uint256 indexed tokenId, address indexed seller);

    function initialize() public initializer {
        __ERC721_init("NFTMarketplace", "NFTMP");
        __AccessControl_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();

        super.grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        super.grantRole(
            MINTER_ROLE,
            0xFbB28e9380B6657b4134329B47D9588aCfb8E33B
        );
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {}

    function listFixedPrice(uint256 tokenId, uint256 price)
        public
        nonReentrant
    {
        require(
            ownerOf(tokenId) == msg.sender,
            "Only item owner can perform this operation"
        );
        require(price > 0, "Price must be greater than zero");

        fixedPriceListings[tokenId] = FixedPriceListing({
            price: price,
            seller: msg.sender,
            active: true
        });

        emit ItemListed(tokenId, msg.sender, price);
    }

    function buyFixedPrice(uint256 tokenId) public payable nonReentrant {
        FixedPriceListing storage listing = fixedPriceListings[tokenId];
        require(listing.active, "Item is not for sale");
        require(listing.price == msg.value, "Incorrect value");

        listing.active = false;
        _transfer(listing.seller, msg.sender, tokenId);
        payable(listing.seller).transfer(msg.value);

        emit ItemSold(tokenId, listing.seller, msg.sender, msg.value);
    }

    function delistFixedPrice(uint256 tokenId) public nonReentrant {
        require(
            fixedPriceListings[tokenId].seller == msg.sender,
            "Only item owner can perform this operation"
        );

        delete fixedPriceListings[tokenId];

        emit ItemDelisted(tokenId, msg.sender);
    }

    function mint(address to, uint256 tokenId) public onlyRole(MINTER_ROLE) {
        _mint(to, tokenId);
    }

    struct AuctionListing {
        uint256 startingPrice;
        mapping(address => uint256) bids; // Mapping to keep track of each bidder's bid
        address[] bidders;
        uint256 highestBid;
        address highestBidder;
        uint256 endTime;
        address seller;
        bool active;
    }

    mapping(uint256 => AuctionListing) public auctionListings;

    event AuctionCreated(
        uint256 indexed tokenId,
        address indexed seller,
        uint256 startingPrice,
        uint256 endTime
    );
    event BidPlaced(
        uint256 indexed tokenId,
        address indexed bidder,
        uint256 bid
    );
    event AuctionFinalized(
        uint256 indexed tokenId,
        address indexed seller,
        address indexed winner,
        uint256 finalPrice
    );
    event AuctionCancelled(uint256 indexed tokenId, address indexed seller);

    function createAuction(
        uint256 tokenId,
        uint256 startingPrice,
        uint256 duration
    ) public nonReentrant {
        require(
            ownerOf(tokenId) == msg.sender,
            "Only item owner can perform this operation"
        );
        require(startingPrice > 0, "Starting price must be greater than zero");
        require(duration > 0, "Duration should be greater than zero");

        AuctionListing storage auction = auctionListings[tokenId];
        auction.startingPrice = startingPrice;
        auction.highestBid = 0;
        auction.highestBidder = address(0);
        auction.endTime = block.timestamp + duration;
        auction.seller = msg.sender;
        auction.active = true;
        delete auction.bidders; // Reset the bidders array for the new auction

        emit AuctionCreated(
            tokenId,
            msg.sender,
            startingPrice,
            block.timestamp + duration
        );
    }

    function placeBid(uint256 tokenId) public payable nonReentrant {
        AuctionListing storage auction = auctionListings[tokenId];
        require(auction.active, "Auction is not active");
        require(block.timestamp < auction.endTime, "Auction has ended");
        require(
            msg.value > auction.highestBid,
            "Bid is not higher than the current highest bid"
        );

        if (auction.bids[msg.sender] == 0) {
            // This is a new bidder, so add them to the bidders array
            auction.bidders.push(msg.sender);
        }

        // Update the bid amount for this bidder
        auction.bids[msg.sender] = msg.value;

        // Refund the previous highest bidder
        if (auction.highestBidder != address(0)) {
            payable(auction.highestBidder).transfer(auction.highestBid);
        }

        // Update the highest bid and bidder
        auction.highestBid = msg.value;
        auction.highestBidder = msg.sender;

        emit BidPlaced(tokenId, msg.sender, msg.value);
    }

    function getAllBidders(uint256 tokenId)
        public
        view
        returns (address[] memory)
    {
        require(_exists(tokenId), "Token does not exist");
        AuctionListing storage auction = auctionListings[tokenId];
        require(auction.active, "Auction is not active");
        return auction.bidders;
    }

    function finalizeAuction(uint256 tokenId) public nonReentrant {
        AuctionListing storage auction = auctionListings[tokenId];
        require(auction.active, "Auction is not active");
        require(
            block.timestamp >= auction.endTime,
            "Auction has not ended yet"
        );
        require(
            msg.sender == auction.highestBidder || msg.sender == auction.seller,
            "Only winner or seller can finalize"
        );

        auction.active = false;

        if (auction.highestBidder != address(0)) {
            _transfer(address(this), auction.highestBidder, tokenId);
            payable(auction.seller).transfer(auction.highestBid);
        } else {
            // No bids were placed, transfer the NFT back to the seller
            _transfer(address(this), auction.seller, tokenId);
        }

        emit AuctionFinalized(
            tokenId,
            auction.seller,
            auction.highestBidder,
            auction.highestBid
        );
    }

    function cancelAuction(uint256 tokenId) public nonReentrant {
        AuctionListing storage auction = auctionListings[tokenId];
        require(auction.active, "Auction is not active");
        require(
            msg.sender == auction.seller,
            "Only seller can cancel the auction"
        );
        require(
            auction.highestBidder == address(0),
            "Cannot cancel auction after bids have been placed"
        );

        auction.active = false;
        _transfer(address(this), auction.seller, tokenId);

        emit AuctionCancelled(tokenId, auction.seller);
    }

    function getFixedPriceListing(uint256 tokenId)
        public
        view
        returns (FixedPriceListing memory listing)
    {
        require(_exists(tokenId), "Token ID does not exist");
        listing = fixedPriceListings[tokenId];
        require(listing.active, "Item is not listed for a fixed price");
        return listing;
    }

    function getAuctionListing(uint256 tokenId)
        public
        view
        returns (
            uint256 startingPrice,
            uint256 highestBid,
            address highestBidder,
            uint256 endTime,
            address seller,
            bool active,
            address[] memory bidders
        )
    {
        require(_exists(tokenId), "Token ID does not exist");

        AuctionListing storage auction = auctionListings[tokenId];
        require(auction.active, "Auction is not active");

        // Return individual properties of the auction
        return (
            auction.startingPrice,
            auction.highestBid,
            auction.highestBidder,
            auction.endTime,
            auction.seller,
            auction.active,
            auction.bidders
        );
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return ownerOf(tokenId) != address(0);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    receive() external payable {
        revert("Direct payments not allowed");
    }

    fallback() external {
        revert("Fallback call not allowed");
    }
}
