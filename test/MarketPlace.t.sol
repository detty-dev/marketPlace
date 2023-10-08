// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Marketplace} from "../src/MarketPlace.sol";
import "../src/ERC721.sol";
import "./Helpers.sol";

contract MarketPlaceTest is Helpers {
    Marketplace MarketPlace;
    OurNFT nft;

    uint256 presentListId;
g
    address _addrA;
    address _addrB;

    uint256 privateKeyX;
    uint256 privateKeyY;

    Marketplace.OrderNFT Data;

    function setUp() public {
        MarketPlace = new Marketplace();
        nft = new OurNFT();

        (_addrA, privateKeyX) = mkaddr("AddrA");
        (_addrB, privateKeyY) = mkaddr("AddrB");

        Data = Marketplace.OrderNFT({
            token: address(nft),
            tokenId: 1,
            price: 2 ether,
            signature: bytes(""),
            deadline: 70 minutes,
            ownerAddress: _addrA,
            isActive: false
        });

        bytes memory signature= constructSig(
         Data.token,
         Data.tokenId,
         Data.price, 
         Data.deadline,
         Data.ownerAddress,
         privateKeyX); 

        Data.signature = signature;

        nft.mint(_addrA, 1);
    }
    
    function testFail_InvaIdOwner() public {
        Data.ownerAddress = _addrB;
        switchSigner(_addrB);
        MarketPlace.createOrder(Data);
    }

    function testFailMinPriceTooLow() public {
        switchSigner(_addrA);
        nft.setApprovalForAll(address(MarketPlace), true);
        Data.price = 0.01 ether;
        MarketPlace.createOrder(Data);
    }
    
    function testFailMinDeadline() public {
        switchSigner(_addrA);
        nft.setApprovalForAll(address(MarketPlace), true);
        Data.deadline = block.timestamp; 
        MarketPlace.createOrder(Data);
    }

    function testFailMinDuration() public {
        switchSigner(_addrA);
        nft.setApprovalForAll(address(MarketPlace), true);
        Data.deadline = uint256(block.timestamp + 59 minutes);
        MarketPlace.createOrder(Data);
    }

    function testFailVaIdSig() public {
        switchSigner(_addrA);
        nft.setApprovalForAll(address(MarketPlace), true);
        Data.deadline = uint256(block.timestamp + 120 minutes);
        Data.signature = constructSig(
            Data.token,
            Data.tokenId,
            Data.price,
            Data.deadline,
            Data.ownerAddress,
            privateKeyY
        );
        MarketPlace.createOrder(Data);
    }

//     // EDIT LISTING
    function testFailEditNonVaIdListing() public {         
        MarketPlace.editOrder(20, 0.01 ether, false);
    }

    function testFailEditListingNotOwner() public {
        switchSigner(_addrA);
        nft.setApprovalForAll(address(MarketPlace), true);
        Data.deadline = uint88(block.timestamp + 120 minutes);
        Data.signature = constructSig(
            Data.token,
            Data.tokenId,
            Data.price,
            Data.deadline,
            Data.ownerAddress,
            privateKeyX
        );
        uint256 ListId = MarketPlace.createOrder(Data);

        switchSigner(_addrB);
        MarketPlace.editOrder(ListId, 0, false);
    }

    function testFailEditOrderAddress() public {
        vm.startPrank(_addrA);
        nft.setApprovalForAll(address(MarketPlace), true);
        uint id = MarketPlace.createOrder(Data);
        vm.stopPrank();
        vm.prank(_addrB);
        MarketPlace.editOrder(id, Data.price, false);
    }
//     // EXECUTE LISTING
    function testFailExecuteNonVaIdListing() public {
        switchSigner(_addrA);
        MarketPlace.executeOrder(10);
    }

    function testFailExecuteExpiredListing() public {
        switchSigner(_addrA);
        nft.setApprovalForAll(address(MarketPlace), true);
        uint id = MarketPlace.createOrder(Data);
        vm.warp(Data.deadline + 10 minutes);
        MarketPlace.executeOrder(id);
    }

    function testFailExecuteIsactive()public {
        vm.startPrank(_addrA);
        nft.setApprovalForAll(address(MarketPlace), true);
       uint Id=  MarketPlace.createOrder(Data);
       MarketPlace.editOrder(Id, Data.price, false);
        vm.stopPrank();
        vm.prank(_addrB);
        MarketPlace.executeOrder(Id);
    }
       
    function testFailExecutePriceNotMet() public {
        vm.startPrank(_addrA);
        nft.setApprovalForAll(address(MarketPlace), true);
        uint Id = MarketPlace.createOrder(Data);
        vm.stopPrank();
        MarketPlace.executeOrder{value:3 ether}(Id);
    }

    function testFailExecutePriceMisMatch() public { 
            vm.startPrank(_addrA);
        nft.setApprovalForAll(address(MarketPlace), true);
        uint Id = MarketPlace.createOrder(Data);
        vm.stopPrank();
        MarketPlace.executeOrder{value:2 ether}(Id);
    }
}




