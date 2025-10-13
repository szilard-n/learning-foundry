// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract MerkleAirdrop is EIP712 {
    using SafeERC20 for IERC20;

    error InvalidMerkleProof();
    error AlreadyClaimed(address account);
    error InvalidSignature();

    bytes32 private constant MESSAGE_TYPEHASH = keccak256("AirdropClaim(address account,uint256 amount)");
    bytes32 private immutable _MERKLE_ROOT;
    IERC20 private immutable _AIRDROP_TOKEN;
    mapping(address claimer => bool claimed) private _hasClaimed;

    struct AirdropClaim {
        address account;
        uint256 amount;
    }

    event Claim(address indexed account, uint256 indexed amount);

    constructor(bytes32 merkleRoot, IERC20 airdropToken) EIP712("MerkleAirdrop", "1") {
        _MERKLE_ROOT = merkleRoot;
        _AIRDROP_TOKEN = airdropToken;
    }

    function claim(address account, uint256 amount, bytes32[] calldata merkleProof, uint8 v, bytes32 r, bytes32 s)
        external
    {
        if (_hasClaimed[account]) {
            revert AlreadyClaimed(account);
        }

        bytes32 message = getMessageDigest(account, amount);
        if (!_isValidSignature(account, message, v, r, s)) {
            revert InvalidSignature();
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

    function getMessageDigest(address account, uint256 amount) public view returns (bytes32) {
        return
            _hashTypedDataV4(keccak256(abi.encode(MESSAGE_TYPEHASH, AirdropClaim({account: account, amount: amount}))));
    }

    function _isValidSignature(address account, bytes32 digest, uint8 v, bytes32 r, bytes32 s)
        internal
        pure
        returns (bool)
    {
        (address actualSigner,,) = ECDSA.tryRecover(digest, v, r, s);
        return actualSigner == account;
    }
}
