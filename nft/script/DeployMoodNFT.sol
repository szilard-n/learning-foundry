// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {MoodNFT} from "../src/MoodNFT.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {CommonBase} from "forge-std/Base.sol";
import {Script} from "forge-std/Script.sol";
import {StdChains} from "forge-std/StdChains.sol";
import {StdCheatsSafe} from "forge-std/StdCheats.sol";
import {StdUtils} from "forge-std/StdUtils.sol";
import {console} from "forge-std/console.sol";

contract DeployMoodNFT is Script {
    function run() external returns (MoodNFT) {
        string memory happySvg = vm.readFile("./img/mood/happy.svg");
        string memory sadSvg = vm.readFile("./img/mood/sad.svg");

        string memory happySvgUri = svgToImageURI(happySvg);
        string memory sadSvgUri = svgToImageURI(sadSvg);

        console.log(happySvgUri);
        console.log(sadSvgUri);

        vm.startBroadcast();
        MoodNFT moodNft = new MoodNFT(svgToImageURI(happySvg), svgToImageURI(sadSvg));
        vm.stopBroadcast();
        return moodNft;
    }

    function svgToImageURI(string memory svg) public pure returns (string memory) {
        string memory baseUrl = "data:image/svg+xml;base64,";
        string memory svgBase64Encoded = Base64.encode(
            bytes(string(abi.encodePacked(svg)))
        );
        return string(abi.encodePacked(baseUrl, svgBase64Encoded));
    }
}
