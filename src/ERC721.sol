//SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@OpenZeppelin/openzeppelin-contracts/src/ERC721.sol";



contract NFTMarketplace  is ERC721 {

    struct Order {
        address tokenOwner;
        address tokenAddress;
        uint256 tokenId;
        uint256 price;
        bool active;
        address seller;
        uint256 deadline;
        bytes signature;
    }

    mapping(uint256 => Order) public orderList;

    uint256 public orderCount = 0;

    IERC721 public erc721Contract;

    constructor(address _erc721Address) {
        erc721Contract = IERC721(_erc721Address);
    }
   
    event OrderCreated( uint256 indexed orderId, address indexed tokenOwner,address indexed tokenAddress,  uint256 tokenId, uint256 price,uint256 deadline);
    event OrderExecuted(uint256 indexed orderId, address indexed buyer, address indexed seller, address tokenAddress, uint256 tokenId, uint256 price);
              
function createOrder(address _tokenAddress, uint256 _tokenId,uint256 _price,uint256 _deadline,bytes memory _signature) external {
        require(_price > 0, "Price must be greater than zero");
        require(_tokenAddress != address(0), "Invalid token address");
        require(block.timestamp < _deadline, "Deadline must be in the future");
        require(erc721Contract.ownerOf(_tokenId) == msg.sender, "Only the owner can create an order");
        require(erc721Contract.getApproved(_tokenId) == address(this), "Must be approved to spend the token");

        orderCount++;
        orderList[orderCount] = Order(
            msg.sender,
            _tokenAddress,
            _tokenId,
            _price,
            true,
            _deadline,
            _signature
        );

        emit OrderCreated(orderCount, msg.sender, _tokenAddress, _tokenId, _price, _deadline);
    }

    function executeOrder(uint256 _orderId, bytes memory _signature) external payable {
        Order storage order = orderList[_orderId];
        require(order.active, "Order is not active");
        require(order.deadline >= block.timestamp, "Order deadline has passed");
        require(msg.value == order.price, "Incorrect payment amount");
        
        erc721Contract.safeTransferFrom(order.tokenOwner, msg.sender, order.tokenId);

        payable(order.tokenOwner).transfer(order.price);

        order.active = false;

        emit OrderExecuted(_orderId, msg.sender, order.tokenOwner, order.tokenAddress, order.tokenId, order.price);
    }
}
    