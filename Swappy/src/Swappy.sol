//SPDX-License-Identifier:MIT

pragma solidity 0.8.28;

import "../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "../lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/openzeppelin-contracts/contracts/utils/Pausable.sol";
contract Swappy is ReentrancyGuard, Ownable,Pausable {

    uint256 public fee; // Fee les than 10%
    uint256 public feesBalance;
    struct Listing{
        address seller;
        address addressNFT;
        uint256 tokenId;
        uint256 price;
    }
    mapping(address=>mapping(uint256=>Listing)) public listing; // I need to do a nested mapping here as tere is no uniqueKey just by NFTadress where to store the struct.

    // Events
    event ListNFT(address indexed addressNFT, address indexed seller, uint256 tokenID, uint256 price);
    event BuyNFT(address indexed addressNFT, address indexed buyer, address indexed seller, uint256 tokenID, uint256 price);
    event CancelList(address indexed addressNFT_, address indexed seller, uint256 tokenID);
    event ModifyFee(uint256 fee);
    event Withdraw(uint256 balance);
    event UpdatePrice(address indexed nftAddress, uint256 tokenId,uint256 newPrice);
    
    constructor() Ownable(msg.sender){

    }

    // Functions
    //1. List NFT
    function listNFT(address addressNFT_, uint256 tokenID_, uint256 price_) external whenNotPaused(){
        require(!isListed(addressNFT_,tokenID_),"The token already exists");
        require(price_!=0,"Price cannot be zero");
        address owner_ = IERC721(addressNFT_).ownerOf(tokenID_);
        require(owner_ == msg.sender,"You are not the owner");
        Listing memory listing_= Listing ({
            seller : msg.sender,
            addressNFT : addressNFT_,
            tokenId : tokenID_,
            price : price_
        });
        listing[addressNFT_][tokenID_] = listing_;
        emit ListNFT(addressNFT_, msg.sender, tokenID_, price_);
    }
    //2. Buy NFT
    function buyNFT(address addressNFT_, uint256 tokenID_) external payable nonReentrant whenNotPaused(){ 
        Listing memory listing_ = listing[addressNFT_][tokenID_];
        require(listing_.addressNFT!=address(0),"NFT does not exist");
        require(listing_.price==msg.value,"The amount you are sending is not the price");
        require(listing_.seller!=msg.sender,"You cannot buy your own NFT");
        require(IERC721(addressNFT_).ownerOf(tokenID_)==listing_.seller,"The seller does not own the NFT any more");

        delete listing[addressNFT_][tokenID_]; // We implement here CEI pattern as well. In BlockChain security is the most important thing.

        uint256 amountForSwappy = (listing_.price*fee)/100;
        uint256 amountForSeller = listing_.price-amountForSwappy;
        IERC721(addressNFT_).safeTransferFrom(listing_.seller,msg.sender,tokenID_);
        (bool success,)= listing_.seller.call{value: amountForSeller}("");
        require(success,"Transfer to seller failed");
        feesBalance += amountForSwappy;
        emit BuyNFT(addressNFT_, msg.sender, listing_.seller, tokenID_, listing_.price);
    }
    //3. Cancel List
    function cancelList(address addressNFT_, uint256 tokenID_) external whenNotPaused{
        Listing memory listing_ = listing[addressNFT_][tokenID_];
        require(listing_.seller==msg.sender,"You are not the owner");
        delete listing[addressNFT_][tokenID_];
        emit CancelList(addressNFT_, listing_.seller, tokenID_);
    }
    //4.Check NFT Exists in Marketplace
    function isListed(address nftAddress_,uint256 tokenId_) public view returns(bool){ // Public function can be called fron the contact itself and outside of the contract
        return listing[nftAddress_][tokenId_].seller != address(0);
    }
    //5.Modify fees
    function modifyFees(uint256 newFee_) external onlyOwner(){
        require(newFee_<10,"The fee must be lower than 10");
        fee = newFee_;
        emit ModifyFee(fee);
    }
    //6. Withdraw fees
    function withdrawFees() external onlyOwner(){
        uint256 balance_ = feesBalance;
        feesBalance = 0;
        (bool success,)=msg.sender.call{value: balance_}("");
        require(success,"Withdraw was not completed");
        emit Withdraw(balance_);
    }
    //7.Update Price
    function updatePrice (address nftAddress_,uint256 tokenId_,uint256 newPrice_) external{
        require(newPrice_>0,"New price must be greater than zero");
        require(msg.sender==listing[nftAddress_][tokenId_].seller,"You are not the owner");
        listing[nftAddress_][tokenId_].price = newPrice_;
        emit UpdatePrice(nftAddress_,tokenId_,newPrice_);
    }
    //8.Pause Contract
    function pauseSmartContract() public onlyOwner(){
        require(!paused(),"Already paused");
        _pause();
    }
    //9.Unpause Contract
    function unPauseSmartContract() public onlyOwner(){
        require(paused(),"Already Unpaused");
        _unpause();
    }
    //10.For injecting ETH in the contract (just in case) without using function BuyNFT.
    receive() external payable {}
}