# 💎 Swappy-NFT-Marketplace
Swappy is a simple yet secure NFT marketplace smart contract written in Solidity. It enables users to list, cancel, update, and buy ERC-721 tokens, with a small fee collected by the contract owner.
# Features

 - List NFTs for sale (ERC-721 standard).

 - Cancel listings anytime by the owner.

 - Update prices of listed NFTs.

 - Buy NFTs safely with ETH transfers.

 - Fee mechanism (configurable, max 10%).

 - Withdraw fees for the owner.

 - Pause / Unpause the marketplace.

 - Direct ETH injection into the contract.

# Security Features

Security in smart contracts is critical. Swappy implements several best practices:

🔹 Checks-Effects-Interactions (CEI) pattern

 - External calls (like ETH transfers and safeTransferFrom) happen after state changes (e.g. deleting a listing).

 - Prevents reentrancy exploits.

🔹 Reentrancy Guard (nonReentrant)

 - Protects the buyNFT function from being called recursively by malicious contracts.

🔹 Pausable mechanism

 - Owner can pause/unpause the contract to stop trading in emergencies.

🔹 Access Control (onlyOwner)

 - Only the contract owner can:

 - Withdraw fees

 - Modify fees

 - Pause/unpause the contract

🔹 Validation with require

 - Prevents zero-price listings

 - Ensures only owners can list/cancel/update

 - Blocks self-purchase

 - Ensures fee is always <10%

🔹 Safe transfers

 - Uses IERC721.safeTransferFrom to ensure NFT transfers follow ERC721 standard.

# Contract Functions

*Listing*


 - function listNFT(address nft, uint256 tokenId, uint256 price);

 - Requires approval from NFT owner.

 - Prevents duplicate listings or zero price.

*Buying*


 - function buyNFT(address nft, uint256 tokenId) payable nonReentrant;

 - Buyer must send exact ETH price.

 - Prevents self-purchase.

 - Ensures seller still owns the NFT.

 - Uses CEI pattern to avoid reentrancy.

*Cancel Listing*


 - function cancelList(address nft, uint256 tokenId);

 - Only seller can cancel.

*Update Price*


 - function updatePrice(address nft, uint256 tokenId, uint256 newPrice);

 - New price must be > 0.

 - Only seller can update.

*Fee Management*


 - modifyFees(uint256 newFee) → Only owner, must be <10%.

 - withdrawFees() → Only owner, withdraws accumulated fees.

 - Emergency Controls

 - pauseSmartContract() / unPauseSmartContract() → Stop/resume trading.

*ETH Injection*


 - receive() allows direct ETH deposits into the contract.

# Events

- ListNFT(address nft, address seller, uint256 tokenId, uint256 price)

- BuyNFT(address nft, address buyer, address seller, uint256 tokenId, uint256 price)

- CancelList(address nft, address seller, uint256 tokenId)

- ModifyFee(uint256 fee)

- Withdraw(uint256 amount)

- UpdatePrice(address nft, uint256 tokenId, uint256 newPrice)

# 🧪 Testing

The test suite (Foundry) covers:

✅ Minting and approving NFTs.

✅ Listing NFTs correctly.

✅ Preventing invalid listings (price = 0, already listed, not owner).

✅ Canceling listings (success + unauthorized reverts).

✅ Buying NFTs (success + invalid scenarios like wrong price, seller no longer owns, self-purchase).

✅ Fee logic (correct distribution + withdraw).

✅ Pausable behavior (pause/unpause, reverts on double actions or unauthorized).

✅ ETH receiving with receive().

<img width="729" height="199" alt="image" src="https://github.com/user-attachments/assets/5fa6e2d4-bf49-417b-b1e5-34b7a62276f9" />
