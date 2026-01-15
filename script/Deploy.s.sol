// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Script.sol";
import {NFT} from "../src/NFT.sol";
import {SimpleVotingSystem} from "../src/SimplevotingSystem.sol";

contract Deploy is Script {
    function run() external {
        console2.log("Deploying NFT and SimpleVotingSystem contracts...");
        vm.startBroadcast();

        NFT Nft = new NFT(msg.sender);
        SimpleVotingSystem voting = new SimpleVotingSystem(address(Nft));
        Nft.grantRole(Nft.MINTER_ROLE(), address(voting));

        vm.stopBroadcast();

        console2.log("NFT deployed at:", address(Nft));
        console2.log("Voting deployed at:", address(voting));
        console2.log("MINTER_ROLE granted to Voting contract");
    }
}