// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "../lib/solmate/src/tokens/ERC721.sol";
import {SignUtils} from "./libraries/SignUtils.sol";

contract Marketplace {
    struct OrderNFT {
        address token;
        uint256 tokenId;
        uint256 price;
        bytes signature;
        // Slot 4
        uint88 deadline;
        address ownerAddress;
        bool isActive;
    }

    mapping(uint256 => OrderNFT) public orders;
    address public _admins;
    uint256 public orderId;

     /* EVENTS */
    event OrderCreated(uint256 indexed orderId, OrderNFT);
    event OrderExecuted(uint256 indexed orderId, OrderNFT);
    event OrderEdited(uint256 indexed orderId, OrderNFT);

    constructor() {}

    function createOrder(OrderNFT calldata list) public returns (uint256 ListId) {
        require(ERC721(list.token).ownerOf(list.tokenId) != msg.sender, "NotOwner");
        require (!ERC721(list.token).isApprovedForAll(msg.sender, address(this)), "Not Eligible");
        require (list.price < 0.01 ether, "MinPriceTooLow");
        require (list.deadline < block.timestamp, "DeadlineTooSoon"); 
        require (list.deadline - block.timestamp < 60 minutes, "MinDurationNotMet");
        require(!SignUtils.isValid(SignUtils.constructMessageHash(
                    list.token,
                    list.tokenId,
                    list.price,
                    list.deadline,
                    list.ownerAddress
                ),
                list.signature,
                msg.sender),
        "InvalidSignature");
          
        OrderNFT storage ListOrder = orders[orderId];
        ListOrder.token = list.token;
        ListOrder.tokenId = list.tokenId;
        ListOrder.price = list.price;
        ListOrder.signature = list.signature;
        ListOrder.deadline = uint88(list.deadline);
        ListOrder.ownerAddress = msg.sender;
        ListOrder.isActive = true;

        emit OrderCreated(orderId, list);
        ListId = orderId;
        orderId++;
        return ListId;
    }

    function executeOrder(uint256 _orderId) public payable {
        require(_orderId >= orderId, "OrderNotExistent");
        OrderNFT storage order = orders[_orderId];
        require (order.deadline < block.timestamp, "OrderExpired");
        require (!order.isActive, "OrderNotActive");
        require (order.price < msg.value, "PriceMismatch(order.price)");
        require (order.price != msg.value, "PriceNotMet(int256(order.price) - int256(msg.value");

        order.isActive = false;
       
        ERC721(order.token).transferFrom(
            order.ownerAddress,
            msg.sender,
            order.tokenId
        );

        payable(order.ownerAddress).transfer(order.price);
        emit OrderExecuted(_orderId, order);
    }

    function editOrder(uint256 _orderId, uint256 _newPrice, bool _active) public {
        require (_orderId >= orderId, "OrderNotExistent");
        OrderNFT storage order = orders[_orderId];
        require (order.ownerAddress != msg.sender, "NotOwner");
        order.price = _newPrice;
        order.isActive = _active;
        emit OrderEdited(_orderId, order);
    }

    function getOrder(uint256 _orderId) public view returns (OrderNFT memory) {
        return orders[_orderId];
    }
}