// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ERC20, ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title DecentralizedStablecoin
 * @author Szilard Nagy
 * Collateral: Exogenous (ETH & BTC)
 * Minting: Algorithmic
 * Relative Stability: Pegged to USD
 *
 * This is the contract meant to be governed by DSCEngine. This contract is just the ERC20
 * implementation for the stablecoin system.
 */
contract DecentralizedStablecoin is ERC20Burnable, Ownable {
    error DecentralizedStablecoin__MustBeMoreThanZero();
    error DecentralizedStablecoin__BurnAmountExceedsBalance();
    error DecentralizedStablecoin__NotZeroAddress();

    constructor(address owner) ERC20("DecentralizedStablecoin", "DSC") Ownable(owner) {}

    function burn(uint256 amount) public override onlyOwner {
        uint256 balance = balanceOf(msg.sender);
        if (amount <= 0) {
            revert DecentralizedStablecoin__MustBeMoreThanZero();
        }

        if (balance < amount) {
            revert DecentralizedStablecoin__BurnAmountExceedsBalance();
        }

        super.burn(amount);
    }

    function mint(address to, uint256 amount) external onlyOwner returns (bool) {
        if (to == address(0)) {
            revert DecentralizedStablecoin__NotZeroAddress();
        }

        if (amount <= 0) {
            revert DecentralizedStablecoin__MustBeMoreThanZero();
        }

        _mint(to, amount);
        return true;
    }
}
