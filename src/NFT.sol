// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;


import "@openzeppelin/contracts/access/AccessControl.sol";
import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

contract NFT is ERC721, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint256 public ID;

    constructor(address admin) ERC721("NFT", "VOTE") {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    function mint(address to) external onlyRole(MINTER_ROLE) returns (uint256 newId) {
        newId = ++ID; 
        _safeMint(to, newId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}