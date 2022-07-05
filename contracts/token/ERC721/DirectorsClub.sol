// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./ERC721.sol";

contract DirectorsClub is ERC721 {
    
    constructor() ERC721("Guildhall Directors Club", "GDC") {
    }
    
    function _baseURI() internal pure override returns (string memory) {
        return "https://texttext";
    }
}