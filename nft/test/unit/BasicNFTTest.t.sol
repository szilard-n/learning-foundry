// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {BasicNFT} from "src/BasicNFT.sol";
import {DeployBasicNFT} from "script/DeployBasicNFT.s.sol";

contract BasicNFTTest is Test {
    string public constant PUG_URI =
    "ipfs://bafybeig37ioir76s7mg5oobetncojcm3c3hxasyd4rvid4jqhy4gkaheg4/?filename=0-PUG.json";

    DeployBasicNFT deployer;
    BasicNFT basicNft;
    address user = makeAddr("user");

    function setUp() public {
        deployer = new DeployBasicNFT();
        basicNft = deployer.run();
    }

    function testNameIsCorrect() public view {
        string memory expectedName = "Dogie";
        string memory actualName = basicNft.name();

        assert(keccak256(abi.encodePacked(expectedName)) == keccak256(abi.encodePacked(actualName)));
    }

    function testCanMintAndHaveABalance() public {
        vm.prank(user);
        basicNft.mintNft(PUG_URI);

        assert(basicNft.balanceOf(user) == 1);
        assert(keccak256(abi.encodePacked(PUG_URI)) == keccak256(abi.encodePacked(basicNft.tokenURI(0))));
    }
}
