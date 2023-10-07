// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/solmate/src/tokens/ERC721.sol";

contract OurNFT is ERC721("TolaNFT", "TNFT") {
    function tokenURI(
        uint256 id
    ) public view virtual override returns (string memory) {
        return "base-marketplace";
    }

    function mint(address recipient, uint256 tokenId) public payable {
        _mint(recipient, tokenId);
    }
}