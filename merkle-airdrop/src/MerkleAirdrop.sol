// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MerkleAirdrop {
    using SafeERC20 for IERC20;

    error InvalidMerkleProof();
    error AlreadyClaimed(address account);

    bytes32 private immutable _MERKLE_ROOT;
    IERC20 private immutable _AIRDROP_TOKEN;
    mapping(address claimer => bool claimed) private _hasClaimed;

    event Claim(address indexed account, uint256 indexed amount);

    constructor(bytes32 merkleRoot, IERC20 airdropToken) {
        _MERKLE_ROOT = merkleRoot;
        _AIRDROP_TOKEN = airdropToken;
    }

    function claim(address account, uint256 amount, bytes32[] calldata merkleProof) external {
        if (_hasClaimed[account]) {
            revert AlreadyClaimed(account);
        }

        // calculate the hash (leaf node) using the account and amount
        // hash twice to prevent second preimage attack (collision)
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(account, amount))));
        if (!MerkleProof.verify(merkleProof, _MERKLE_ROOT, leaf)) {
            revert InvalidMerkleProof();
        }

        _hasClaimed[account] = true;
        emit Claim(account, amount);
        _AIRDROP_TOKEN.safeTransfer(account, amount);
    }

    function getMerkleRoot() external view returns (bytes32) {
        return _MERKLE_ROOT;
    }

    function getAirdropToken() external view returns (IERC20) {
        return _AIRDROP_TOKEN;
    }
}
