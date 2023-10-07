// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Marketplace} from "../src/MarketPlace.sol";
import "../src/ERC721.sol";
import "./Helpers.sol";

contract MarketPlaceTest is Helpers {
    Marketplace MarketPlace;
    OurNFT nft;

    uint256 presentListId;

    address _addrA;
    address _addrB;

    uint256 privateKeyX;
    uint256 privateKeyY;

    Marketplace.OrderNFT  Data;

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
            deadline: 1,
            ownerAddress: address(_addrA),
            isActive: false
        });

        nft.mint(_addrA, 1);
    }
    function testInvalidOwner() public {
        Data.ownerAddress = _addrB;
        switchSigner(_addrB);

        vm.expectRevert(Marketplace.NotOwner.selector);
        MarketPlace.createOrder(Data);
    }

    function testNonEligibleNFT() public {
        switchSigner(_addrA);
        vm.expectRevert(Marketplace.NotApproved.selector);
        MarketPlace.createOrder(Data);
    }

    function testMinPriceTooLow() public {
        switchSigner(_addrA);
        nft.setApprovalForAll(address(MarketPlace), true);
        Data.price = 0;
        vm.expectRevert(Marketplace.MinPriceTooLow.selector);
        MarketPlace.createOrder(Data);
    }

    function testMinDeadline() public {
        switchSigner(_addrA);
        nft.setApprovalForAll(address(MarketPlace), true);
        vm.expectRevert(Marketplace.DeadlineTooSoon.selector);
        MarketPlace.createOrder(Data);
    }

    function testMinDuration() public {
        switchSigner(_addrA);
        nft.setApprovalForAll(address(MarketPlace), true);
        Data.deadline = uint88(block.timestamp + 59 minutes);
        vm.expectRevert(Marketplace.MinDurationNotMet.selector);
        MarketPlace.createOrder(Data);
    }

    function testValidSig() public {
        switchSigner(_addrA);
        nft.setApprovalForAll(address(MarketPlace), true);
        Data.deadline = uint88(block.timestamp + 120 minutes);
        Data.sig = constructSig(
            Data.token,
            Data.tokenId,
            Data.price,
            Data.deadline,
            Data.lists,
            privateKeyY
        );
        vm.expectRevert(Marketplace.InvalidSignature.selector);
        MarketPlace.createOrder(Data);
    }

    // EDIT LISTING
    function testEditNonValidListing() public {
        switchSigner(_addrA);
        vm.expectRevert(Marketplace.ListingNotExistent.selector);
        MarketPlace.editListing(1, 0, false);
    }

    function testEditListingNotOwner() public {
        switchSigner(_addrA);
        nft.setApprovalForAll(address(MarketPlace), true);
        Data.deadline = uint88(block.timestamp + 120 minutes);
        Data.sig = constructSig(
            Data.token,
            Data.tokenId,
            Data.price,
            Data.deadline,
            Data.lists,
            privateKeyX
        );
        uint256 ListId = MarketPlace.createOrder(Data);

        switchSigner(_addrB);
        vm.expectRevert(Marketplace.NotOwner.selector);
        MarketPlace.editListing(ListId, 0, false);
    }

    function testEditListing() public {
        switchSigner(_addrA);
        nft.setApprovalForAll(address(MarketPlace), true);
        Data.deadline = uint88(block.timestamp + 120 minutes);
        Data.sig = constructSig(
            Data.token,
            Data.tokenId,
            Data.price,
            Data.deadline,
            Data.lists,
            privateKeyX
        );
        uint256 ListId = MarketPlace.createOrder(Data);
        MarketPlace.editListing(ListId, 0.01 ether, false);

        Marketplace.OrderNFT memory t = MarketPlace.getListing(ListId);
        assertEq(t.price, 0.01 ether);
        assertEq(t.active, false);
    }

    // EXECUTE LISTING
    function testExecuteNonValidListing() public {
        switchSigner(_addrA);
        vm.expectRevert(Marketplace.ListingNotExistent.selector);
        MarketPlace.executeOrder(_orderId);(1);
    }

    function testExecuteExpiredListing() public {
        switchSigner(_addrA);
        nft.setApprovalForAll(address(MarketPlace), true);
    }

    function testExecuteListingNotActive() public {
        switchSigner(_addrA);
        nft.setApprovalForAll(address(MarketPlace), true);
        Data.deadline = uint88(block.timestamp + 120 minutes);
        Data.sig = constructSig(
            Data.token,
            Data.tokenId,
            Data.price,
            Data.deadline,
            Data.lists,
            privateKeyX
        );
        uint256 lId = MarketPlace.createOrder(Data);
        MarketPlace.editListing(lId, 0.01 ether, false);
        switchSigner(_addrB);
        vm.expectRevert(Marketplace.ListingNotActive.selector);
        MarketPlace.executeOrder(_orderId);(lId);
    }

    function testExecutePriceNotMet() public {
        switchSigner(_addrA);
        nft.setApprovalForAll(address(MarketPlace), true);
        Data.deadline = uint88(block.timestamp + 120 minutes);
        Data.sig = constructSig(
            Data.token,
            Data.tokenId,
            Data.price,
            Data.deadline,
            Data.lists,
            privateKeyX
        );
        uint256 lId = MarketPlace.createOrder(Data);
        switchSigner(_addrB);
        vm.expectRevert(
            abi.encodeWithSelector(
                Marketplace.PriceNotMet.selector,
                Data.price - 0.9 ether
            )
        );
        MarketPlace.executeOrder(_orderId);{value; 0.9 ether}(lId);
    }

    function testExecutePriceMismatch() public {
        switchSigner(_addrA);
        nft.setApprovalForAll(address(MarketPlace), true);
        Data.deadline = uint88(block.timestamp + 60 minutes);
        Data.sig = constructSig(
            Data.token,
            Data.tokenId,
            Data.price,
            Data.deadline,
            Data.lists,
            privateKeyX
        );
        uint256 ListId = MarketPlace.createOrder(Data);
        switchSigner(_addrB);
        vm.expectRevert(
            abi.encodeWithSelector(Marketplace.PriceMismatch.selector, Data.price)
        );
        MarketPlace.executeOrder(_orderId);{value: 1.0 ether}(ListId);
    }

    function testExecute() public {
        switchSigner(_addrA);
        nft.setApprovalForAll(address(MarketPlace), true);
        Data.deadline = uint88(block.timestamp + 120 minutes);
        // Data.price = 1 ether;
        Data.sig = constructSig(
            Data.token,
            Data.tokenId,
            Data.price,
            Data.deadline,
            Data.lists,
            privateKeyX
        );
        uint256 ListId = MarketPlace.createOrder(Data);
        switchSigner(_addrB);
        uint256 userABalanceBefore = _addrA.balance;

        MarketPlace.executeOrder(_orderId);{value: Data.price}(ListId);

        uint256 userABalanceAfter = _addrA.balance;

        Marketplace.OrderNFT memory t = MarketPlace.getListing(ListId);
        assertEq(t.price, 1 ether);
        assertEq(t.active, false);

        assertEq(t.active, false);
        assertEq(ERC721(Data.token).ownerOf(Data.tokenId), _addrB);
        assertEq(userABalanceAfter, userABalanceBefore + Data.price);
    }
}