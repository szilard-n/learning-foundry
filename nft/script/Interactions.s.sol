// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
import {BasicNFT} from "src/BasicNFT.sol";

contract MinBasicNFT is Script {
    string public constant PUG_URI =
    "ipfs://bafybeig37ioir76s7mg5oobetncojcm3c3hxasyd4rvid4jqhy4gkaheg4/?filename=0-PUG.json";

    function run() external {
        address recentDeployment = DevOpsTools.get_most_recent_deployment("BasicNFT", block.chainid);
    }

    function mintNftOnContract(address contractAddress) public {
        vm.startBroadcast();
        BasicNFT(contractAddress).mintNft(PUG_URI);
        vm.stopBroadcast();
    }
}