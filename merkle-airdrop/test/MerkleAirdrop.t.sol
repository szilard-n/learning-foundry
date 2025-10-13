// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {MerkleAirdrop} from "src/MerkleAirdrop.sol";
import {BegelToken} from "src/BegelToken.sol";
import {Test} from "forge-std/Test.sol";
import {DeployMerkleAirdrop} from "script/DeployMerkleAirdrop.s.sol";

contract MerkleAirdropTest is Test {
    MerkleAirdrop private _airdrop;
    BegelToken private _token;

    bytes32 private constant _MERKLE_ROOT = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;
    uint256 private constant _AMOUNT_TO_CLAIM = 25 * 1e18;
    uint256 private constant _AMOUNT_TO_SEND = _AMOUNT_TO_CLAIM * 4;
    bytes32[] private _proof;
    address private gasPayer;
    address private user;
    uint256 private userPrivateKey;

    function setUp() public {
        DeployMerkleAirdrop deployer = new DeployMerkleAirdrop();
        (_airdrop, _token) = deployer.deploy();

        gasPayer = makeAddr("gasPayer");
        (user, userPrivateKey) = makeAddrAndKey("user");

        _proof = new bytes32[](2);
        _proof[0] = 0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a;
        _proof[1] = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    }

    function testUsersCanClaim() public {
        uint256 startingBalance = _token.balanceOf(user);
        bytes32 digest = _airdrop.getMessageDigest(user, _AMOUNT_TO_CLAIM);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, digest);

        vm.prank(gasPayer);
        _airdrop.claim(user, _AMOUNT_TO_CLAIM, _proof, v, r, s);

        uint256 endingBalance = _token.balanceOf(user);
        assertEq(endingBalance - startingBalance, _AMOUNT_TO_CLAIM);
    }
}
