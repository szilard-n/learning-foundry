// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract BegelToken is ERC20, Ownable {
    string private constant NAME = "Begel Token";
    string private constant SYMBOL = "BEGEL";

    constructor() ERC20(NAME, SYMBOL) Ownable(msg.sender) {}

    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }
}
