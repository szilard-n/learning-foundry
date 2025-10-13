// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Script} from "forge-std/Script.sol";
import {MerkleAirdrop} from "src/MerkleAirdrop.sol";
import {BegelToken} from "src/BegelToken.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DeployMerkleAirdrop is Script {
    bytes32 private _merkleRoot = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;
    uint256 private _amountToTransfer = 4 * 25 * 1e18;

    function run() external returns (MerkleAirdrop, BegelToken) {
        return deploy();
    }

    function deploy() public returns (MerkleAirdrop, BegelToken) {
        vm.startBroadcast();
        BegelToken token = new BegelToken();
        MerkleAirdrop airdrop = new MerkleAirdrop(_merkleRoot, token);
        token.mint(token.owner(), _amountToTransfer);
        token.transfer(address(airdrop), _amountToTransfer);
        vm.stopBroadcast();
        return (airdrop, token);
    }
}
