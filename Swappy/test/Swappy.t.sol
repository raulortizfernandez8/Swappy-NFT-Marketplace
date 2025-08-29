//SPDX-License-Identifier:MIT

pragma solidity 0.8.28;

import "../lib/forge-std/src/Test.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "../src/Swappy.sol";

contract MockNFT is ERC721{
    constructor() ERC721("Mock NFT","MNFT"){}

    function mint_(address to_, uint256 tokenId_) external{
        _mint(to_, tokenId_);
    }
}
contract SwappyTest is Test {
     Swappy swappy;
     MockNFT nft;
     address deployer = vm.addr(1);
     address user = vm.addr(2);
     address user2 = vm.addr(3);
     uint256 tokenId = 0;
     struct Listing{
        address seller;
        address addressNFT;
        uint256 tokenId;
        uint256 price;
    }
    function setUp() public{
        vm.startPrank(deployer);

        swappy = new Swappy();
        nft = new MockNFT(); // Here I deploy the nft as

        vm.stopPrank();

        vm.startPrank(user);
        nft.mint_(user,tokenId);
        vm.stopPrank();
    }
    function testMintNFT() public view{
        address owner = nft.ownerOf(tokenId);
        assert(owner==user);
    }
    function testShouldRevertAlreadyListed() public{
        uint256 price_ = 2;
        vm.startPrank(user);
        (address sellerBefore,,,) = swappy.listing(address(nft),tokenId);
        swappy.listNFT(address(nft), tokenId, price_);
        (address sellerAfter,,,) = swappy.listing(address(nft),tokenId);
        assert(sellerBefore==address(0) && sellerAfter==user);

        vm.startPrank(user);
        vm.expectRevert("The token already exists");
        swappy.listNFT(address(nft), tokenId, price_);
        vm.stopPrank();
    }
    function testShouldRevertPriceLessThanZero() public{
        uint256 price_ = 0;
        vm.startPrank(user);
        vm.expectRevert("Price cannot be zero");
        swappy.listNFT(address(nft), tokenId, price_);
        vm.stopPrank();
    }
    function testShouldRevertNotOwnerList() public{
        uint256 price_=2;
        uint256 tokenId_ = 1;
        nft.mint_(user2,tokenId_);

        vm.startPrank(user);

        vm.expectRevert("You are not the owner");
        swappy.listNFT(address(nft), tokenId_, price_);

        vm.stopPrank();
    }
    function testListNFT() public{
        uint256 price_ = 2;
        vm.startPrank(user);
        (address sellerBefore,,,) = swappy.listing(address(nft),tokenId);
        swappy.listNFT(address(nft), tokenId, price_);
        (address sellerAfter,,,) = swappy.listing(address(nft),tokenId);
        assert(sellerBefore==address(0) && sellerAfter==user);

        vm.stopPrank();
    }
    function testCancelListShouldRevertIfNotOwner() public{
        uint256 price_ = 2;
        vm.startPrank(user);
        (address sellerBefore,,,) = swappy.listing(address(nft),tokenId);
        swappy.listNFT(address(nft), tokenId, price_);
        (address sellerAfter,,,) = swappy.listing(address(nft),tokenId);
        assert(sellerBefore==address(0) && sellerAfter==user);
        vm.stopPrank();

        vm.startPrank(user2);
        vm.expectRevert("You are not the owner");
        swappy.cancelList(address(nft), tokenId);
        vm.stopPrank(); 
    }
    function testCancelList() public{
        uint256 price_ = 2;
        vm.startPrank(user);
        (address sellerBefore,,,) = swappy.listing(address(nft),tokenId);
        swappy.listNFT(address(nft), tokenId, price_);
        (address sellerAfter,,,) = swappy.listing(address(nft),tokenId);
        assert(sellerBefore==address(0) && sellerAfter==user);
        vm.stopPrank();

        vm.startPrank(user);
        swappy.cancelList(address(nft), tokenId);
        (sellerAfter,,,) = swappy.listing(address(nft),tokenId);
        assert(sellerAfter == address(0));
        vm.stopPrank(); 
    }
    function testCanNotBuyUnlistedNFT() public{
        uint256 tokenId_ = 3;
        vm.startPrank(user);
        
        vm.expectRevert("NFT does not exist");
        swappy.buyNFT(address(nft),tokenId_);

        vm.stopPrank();
    }
    function testShouldRevertNotCorrectPrice() public{
        uint256 price_ = 2;

        vm.startPrank(user);
        (address sellerBefore,,,) = swappy.listing(address(nft),tokenId);
        swappy.listNFT(address(nft), tokenId, price_);
        (address sellerAfter,,,) = swappy.listing(address(nft),tokenId);
        assert(sellerBefore==address(0) && sellerAfter==user);

        vm.stopPrank();
        
        vm.startPrank(user2);
        vm.deal(user2,5);

        vm.expectRevert("The amount you are sending is not the price");
        swappy.buyNFT{value:price_-1}(address(nft),tokenId);

        vm.stopPrank();
    }
    function testCanNotBuyYourOwnNFT() public{
        uint256 price_ = 2;
        vm.startPrank(user);
        (address sellerBefore,,,) = swappy.listing(address(nft),tokenId);
        swappy.listNFT(address(nft), tokenId, price_);
        (address sellerAfter,,,) = swappy.listing(address(nft),tokenId);
        assert(sellerBefore==address(0) && sellerAfter==user);

        vm.deal(user,5);

        vm.expectRevert("You cannot buy your own NFT");
        swappy.buyNFT{value:price_}(address(nft),tokenId);

        vm.stopPrank();
    }
    function testSellerNotOwnerAnyMore() public{
        uint256 price_ = 2;

        vm.startPrank(user);
        (address sellerBefore,,,) = swappy.listing(address(nft),tokenId);
        swappy.listNFT(address(nft), tokenId, price_); // Seller list NFT
        (address sellerAfter,,,) = swappy.listing(address(nft),tokenId);
        assert(sellerBefore==address(0) && sellerAfter==user);
        nft.approve(address(swappy), tokenId);
        nft.transferFrom(user, address(5), tokenId); //Seller transfer NFT without cancelling the list.
        vm.stopPrank();

        vm.startPrank(user2);

        vm.deal(user2,5);
        vm.expectRevert("The seller does not own the NFT any more");
        swappy.buyNFT{value:price_}(address(nft),tokenId); // Another user try to buy the NFT, but it is not in marketplace

        vm.stopPrank();
    }
    function testBuyNFT() public{
        uint256 price_ = 2;

        vm.startPrank(user);
        (address sellerBefore,,,) = swappy.listing(address(nft),tokenId);
        swappy.listNFT(address(nft), tokenId, price_);
        (address sellerAfter,,,) = swappy.listing(address(nft),tokenId);
        assert(sellerBefore==address(0) && sellerAfter==user);
        nft.approve(address(swappy), tokenId);
        vm.stopPrank();

        vm.startPrank(user2);
        vm.deal(user2,5);

        uint256 balanceBefore = user.balance;
        address ownerBefore = nft.ownerOf(tokenId);
        (address sellerBefore2,,,) = swappy.listing(address(nft),tokenId);

        swappy.buyNFT{value:price_}(address(nft),tokenId);

        (address sellerAfter2,,,) = swappy.listing(address(nft),tokenId);
        address ownerAfter = nft.ownerOf(tokenId);
        uint256 balanceAfter = user.balance;
        uint256 feeAmount = (price_ * swappy.fee()) / 100;
        assert(sellerBefore2 == user && sellerAfter2 == address(0));
        assert(ownerBefore==user&&ownerAfter==user2);
        assert(balanceBefore+(price_-feeAmount)==balanceAfter);

        vm.stopPrank();
    }
    function testIsListedReturnsTrue() public{
        uint256 price_ = 2;
        vm.startPrank(user);
        (address sellerBefore,,,) = swappy.listing(address(nft),tokenId);
        swappy.listNFT(address(nft), tokenId, price_);
        (address sellerAfter,,,) = swappy.listing(address(nft),tokenId);
        assert(sellerBefore==address(0) && sellerAfter==user);

        bool exists = swappy.isListed(address(nft), tokenId);
        assert(exists==true);
        vm.stopPrank();
    }
    function testIsListedReturnsFalse() public view{
        bool exists = swappy.isListed(address(nft), tokenId);
        assert(exists==false);
    }
    function testCanNotModifyFeeGreaterThanZero() public{
        vm.startPrank(deployer);

        uint256 newFee = 11;
        vm.expectRevert("The fee must be lower than 10");
        swappy.modifyFees(newFee);

        vm.stopPrank();
    }
    function testModifyFeeNotOwner() public{
        vm.startPrank(user);
        uint256 newFee = 3;
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user));
        swappy.modifyFees(newFee);

        vm.stopPrank();
    }
    function testModifyFee() public{
        vm.startPrank(deployer);
        
        uint256 feeBefore = swappy.fee();
        uint256 newFee = 9;
        swappy.modifyFees(newFee);
        uint256 feeAfter = swappy.fee();
        assert(newFee==feeAfter&&feeBefore!=feeAfter);

        vm.stopPrank();
    }
    function testWithdrawFeesNotOwner() public{
       vm.startPrank(user);

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user));
        swappy.withdrawFees();

        vm.stopPrank(); 
    }
    function testWithdrawFees() public{
        vm.startPrank(deployer);
        uint256 balanceBefore = deployer.balance;
        uint256 feeAmount = swappy.feesBalance();
        swappy.withdrawFees();
        uint256 balanceAfter = deployer.balance;
        assert(balanceAfter==balanceBefore+feeAmount);
        vm.stopPrank();
    }
    function testUpdatePriceCanNotBeZero() public{
        vm.startPrank(user);
        uint256 newPrice = 0;
        vm.expectRevert("New price must be greater than zero");
        swappy.updatePrice(address(nft), tokenId, newPrice);
        vm.stopPrank();
    }
     function testUpdatePriceNotOwner() public{
        vm.startPrank(user);
        uint256 price_ = 1;
        (address sellerBefore,,,) = swappy.listing(address(nft),tokenId);
        swappy.listNFT(address(nft), tokenId, price_);
        (address sellerAfter,,,) = swappy.listing(address(nft),tokenId);
        assert(sellerBefore==address(0) && sellerAfter==user);
        vm.stopPrank();

        vm.startPrank(user2);
        uint256 newPrice_ = 2;
        vm.expectRevert("You are not the owner");
        swappy.updatePrice(address(nft), tokenId, newPrice_);
        vm.stopPrank();
    }
    function testUpdatePrice() public{
         vm.startPrank(user);
        uint256 price_ = 1;
        (address sellerBefore,,,) = swappy.listing(address(nft),tokenId);
        swappy.listNFT(address(nft), tokenId, price_);
        (address sellerAfter,,,) = swappy.listing(address(nft),tokenId);
        assert(sellerBefore==address(0) && sellerAfter==user);
        
        uint256 newPrice_ = 2;
        swappy.updatePrice(address(nft), tokenId, newPrice_);
        (,,,uint256 priceAfter) = swappy.listing(address(nft),tokenId);
        assert(priceAfter==newPrice_);
        vm.stopPrank();
    }
    function testShouldRevertPauseContractTwice() public{
        vm.startPrank(deployer);
        swappy.pauseSmartContract();
        vm.expectRevert("Already paused");
        swappy.pauseSmartContract();
        vm.stopPrank();
    }
      function testPauseContractNotOwner() public{
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user));
        swappy.pauseSmartContract();
        vm.stopPrank();
    }
      function testPauseContract() public{
        vm.startPrank(deployer);
        swappy.pauseSmartContract();
        vm.stopPrank();
    }
    
    function testShouldRevertUnpauseContractTwice() public{
        vm.startPrank(deployer);
        swappy.pauseSmartContract();
        swappy.unPauseSmartContract();
        vm.expectRevert("Already Unpaused");
        swappy.unPauseSmartContract();
        vm.stopPrank();
    }
      function testUnpauseContractNotOwner() public{
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user));
        swappy.unPauseSmartContract();
        vm.stopPrank();
    }
      function testUnpauseContract() public{
        vm.startPrank(deployer);
        swappy.pauseSmartContract();
        swappy.unPauseSmartContract();
        vm.stopPrank();
    }
        function testReceiveETH() public{ // We ensure the contract can receive ether.
            uint256 amount = 1 ether;
            (bool success, ) = address(swappy).call{value: amount}("");
            assert(success);
            assert(address(swappy).balance == amount);
    }
}