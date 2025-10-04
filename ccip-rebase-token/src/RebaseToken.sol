// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title RebaseToken
 * @author Szilard Nagy
 * @notice This is a cross-chain rebase token that incentivizes users to deposit into a vault to gain interest and rewards.
 * @notice The interest rate in the smart contract can only decrease
 * @notice Each user will have their own interest rate, which will be the interest rate at the time of depositing
 */
contract RebaseToken is ERC20, Ownable, AccessControl {
    error RebaseToken__InterestRateCanOnlyDecrease(
        uint256 oldInterestRate,
        uint256 newInterestRate
    );

    string private constant NAME = "Rebase Token";
    string private constant SYMBOL = "RBT";
    uint256 private constant PRECESION_FACTOR = 1e18;
    bytes32 private constant MINT_AND_BURN_ROLE =
        keccak256("MINT_AND_BURN_ROLE");

    uint256 private s_interestRate = (5 * PRECESION_FACTOR) / 1e8; // 10^-8 == 1 / 10^8
    mapping(address => uint256) private s_userInterestRate;
    mapping(address => uint256) private s_userLastUpdatedTimestamp;

    event InterestRateSet(uint256 newInterestRate);

    constructor() ERC20(NAME, SYMBOL) Ownable(msg.sender) {}

    function grantMintAndBurnRole(address _account) external onlyOwner {
        _grantRole(MINT_AND_BURN_ROLE, _account);
    }

    /**
     * @notice Set the interest rate in the contract
     * @param _newInterestRate The new interest rate to be set
     * @dev The interest rate can only decrease
     */
    function setInterestRate(uint256 _newInterestRate) external onlyOwner {
        if (_newInterestRate >= s_interestRate) {
            revert RebaseToken__InterestRateCanOnlyDecrease(
                s_interestRate,
                _newInterestRate
            );
        }
        s_interestRate = _newInterestRate;
        emit InterestRateSet(_newInterestRate);
    }

    /**
     * @notice Mint rebase tokens to a user
     * @param _to The address of the user to mint the tokens to
     * @param _amount The amount of tokens to mint
     */
    function mint(
        address _to,
        uint256 _amount,
        uint256 _userInterestRate
    ) external onlyRole(MINT_AND_BURN_ROLE) {
        _mintAccruedInterest(_to);
        s_userInterestRate[_to] = _userInterestRate;
        _mint(_to, _amount);
    }

    /**
     * @notice Burn the user tokens when they withdraw from the vault
     * @param _from The address of the user to burn the tokens from
     * @param _amount The amount of tokens to burn
     */
    function burn(
        address _from,
        uint256 _amount
    ) external onlyRole(MINT_AND_BURN_ROLE) {
        if (_amount == type(uint256).max) {
            _amount = super.balanceOf(_from);
        }
        _mintAccruedInterest(_from);
        _burn(_from, _amount);
    }

    /**
     * @notice Calculate the balance for the user including the interest that has accumulated since the last update.
     * (principle balance) + some interest that has accrued
     * @param _user The address of the user
     * @return The balance of the user including the interest that has accumulated since the last update
     * @dev The balance is calculated as: principle balance * interest rate
     */
    function balanceOf(address _user) public view override returns (uint256) {
        // get current principle balance (the number of tokens that have actually been mintend to the user)
        // multiply the principle balance by the interest rate
        return
            (super.balanceOf(_user) *
                _calculateAccumulatedInterestSinceLastUpdate(_user)) /
            PRECESION_FACTOR;
    }

    /**
     * @notice Transfer tokens from one user to another
     * @param _recipient The address of the recipient
     * @param _amount The amount of tokens to transfer
     * @return A boolean value indicating whether the operation succeeded
     */
    function transfer(
        address _recipient,
        uint256 _amount
    ) public override returns (bool) {
        _mintAccruedInterest(msg.sender);
        _mintAccruedInterest(_recipient);

        if (_amount == type(uint256).max) {
            _amount = super.balanceOf(msg.sender);
        }

        if (balanceOf(_recipient) == 0) {
            s_userInterestRate[_recipient] = s_userInterestRate[msg.sender];
        }

        return super.transfer(_recipient, _amount);
    }

    /**
     * @notice Transfer tokens from one user to another on behalf of the sender
     * @param _sender The address of the sender
     * @param _recipient The address of the recipient
     * @param _amount The amount of tokens to transfer
     * @return A boolean value indicating whether the operation succeeded
     */
    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) public override returns (bool) {
        _mintAccruedInterest(_sender);
        _mintAccruedInterest(_recipient);

        if (_amount == type(uint256).max) {
            _amount = super.balanceOf(_sender);
        }

        if (balanceOf(_recipient) == 0) {
            s_userInterestRate[_recipient] = s_userInterestRate[_sender];
        }

        return super.transferFrom(_sender, _recipient, _amount);
    }

    /**
     * @notice Get the principle balance of a user (the amount of tokens that have actually
     been minted to the user not including the interest accrued since the last update)
     * @param _user The address of the user
     * @return The principle balance of the user
     */
    function principleBalanceOf(address _user) external view returns (uint256) {
        return super.balanceOf(_user);
    }

    /**
     * @notice Calculate the accumulated interest since the last update for a user
     * @param _user The address of the user to calculate the interest for
     * @return linearInterest The accumulated interest since the last update
     */
    function _calculateAccumulatedInterestSinceLastUpdate(
        address _user
    ) internal view returns (uint256 linearInterest) {
        // we need to calculate the interest that has accumulated since the last update
        // this is going to be linear growth with time
        // 1. calculate the time since the last update
        // 2. calculate the amount of linear growth
        uint256 timeElapsed = block.timestamp -
            s_userLastUpdatedTimestamp[_user];
        linearInterest =
            PRECESION_FACTOR +
            (s_userInterestRate[_user] * timeElapsed);
    }

    /**
     * @notice Mnit the accrued interest to the user since the last time they interacted with the contract
     * @param _user The address of the user to mint the interest to
     */
    function _mintAccruedInterest(address _user) internal {
        // (1) find their current balance of rebase tokens that have been mintented to their user -> principal balance
        uint256 previousPrincipleBalance = super.balanceOf(_user);
        // (2) calculate their current balance including any interest -> balanceOf
        uint256 currentBalance = balanceOf(_user);
        // calculate the number of tokens that need to be minted to the user -> (1) - (2)
        uint256 balanceIncrease = currentBalance - previousPrincipleBalance;
        // set the user's last updated timestamp
        s_userLastUpdatedTimestamp[_user] = block.timestamp;
        _mint(_user, balanceIncrease);
    }

    /**
     * @notice Get the current interest rate that is currently set in the contract
     * @return The current interest rate in the contract
     */
    function getInterestRate() external view returns (uint256) {
        return s_interestRate;
    }

    /**
     * @notice Get the interest rate of a user
     * @param _user The address of the user
     * @return The interest rate of the user
     */
    function getUserInterestRate(
        address _user
    ) external view returns (uint256) {
        return s_userInterestRate[_user];
    }
}
