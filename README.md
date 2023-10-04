createOrder
    - set token owner to msg.sender 
    - address tokenAddress;
    - uint256 tokenId;
    - uint256 price;
    - bool active;
    - address seller;
    - uint256 deadline;
    - bytes signature;

    checks to create ERC721 tokens
     - require the token user address is active to sell nft
    - require the price > zero
    - require invalid user address cant create erc721
    - require owner approve address(this) to spend tokenAddress
    - require tokenAddresss ! address(0)
    - require address has code
    -require deadline > block.stamp
    - require there is deadline for the token to be sold, if the deadline passes it cant be sold again
    
    logic
    - increase the orderLIst
    - store in data in storage
    -emit event

executeOrder (payable)

-orderId

    check for executing orders
    - require signature is signed by owner
    - require msg.value == order.price
    - require blockstamp <= order.deadline
    - require the seller signs the previous data before executing new order
    - require the signature is verified to be the owner address before executing order
    
    logic 
    - retrieve data from storage
    -transfer nft from sellers to buyers
    - transfer ethers from buyer to seller
    -emit event
 
- 