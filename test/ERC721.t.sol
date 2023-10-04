function testSignature() public {
        uint256 privateKey = 0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6;
        //  address seller;
        address tokenAddress = 0x14dC79964da2C08b23698B3D3cc7Ca32193d9955;
        uint256 tokenId = 0;
        uint256 price = 2;
        uint256 deadline = 234567890;
      
        address seller = vm.addr(privateKey);

       
        bytes32 messageHash = keccak256(
            abi.encodePacked(seller, tokenAddress, tokenId, price,  deadline)
        );

        (uint8 v,bytes32 r, bytes32 s) = vm.sign(privateKey, messageHash);
        bytes memory signature = abi.encodePacked(r, s, v);
        address signer = ecrecover(messageHash, v, r, s);

        assertEq(signer, seller);

        // Test invalid message
        bytes32 invalidHash = keccak256("Not signed by Seller");
        signer = ecrecover(invalidHash, v, r, s);

        market.createListing(tokenAddress, tokenId, price, signature, deadline);

        assertTrue(signer != seller);
    }