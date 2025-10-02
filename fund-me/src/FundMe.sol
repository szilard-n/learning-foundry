// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {PriceConverter} from "./PriceConverter.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

error FundMe__NotOwner();

/**
 * @title A sample Funding Contract
 * @author Patrick Collins
 * @notice This contract is for creating a sample funding contract
 * @dev This implements price feeds as our library
 */
contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MIN_USD = 5e18; // 5 dollars with 18 decimal places

    mapping(address => uint256) private s_addressToAmountFunded;
    address[] private s_funders;

    address private immutable i_owner;
    AggregatorV3Interface private s_preiceFeed;

    constructor(address priceFeed) {
        i_owner = msg.sender;
        s_preiceFeed = AggregatorV3Interface(priceFeed);
    }

    function fund() public payable {
        require(
            msg.value.getConversionRate(s_preiceFeed) >= MIN_USD,
            "Transfered amount too small"
        );
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        uint256 fundersLength = s_funders.length; // read from sotrage once for less gas
        for (
            uint256 funderIndex = 0;
            funderIndex < fundersLength;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        // reset array
        s_funders = new address[](0);
        // actually withdraw the funds
        // three different ways: transfer, send, call

        // transfer
        // msg.sender is and address and we need to cast it to payable address
        // capped at 2300 gas and throws error if the transaction fails. It's automatically reverted
        // payable(msg.sender).transfer(address(this).balance);

        // send
        // capped at 2300 gas and returns a bool that we can handle to revert
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");

        // call
        // forwards al gas or set gas and returns a bool
        (bool callSuccess /*bytes memory dataReturned */, ) = payable(
            msg.sender
        ).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    modifier onlyOwner() {
        // _; -> execute function frist and then this modifier
        // require(msg.sender == i_owner, "Sender is not owner");
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner(); // more gas efficient than require with a string
        }
        _; // execute this modifier first and then the rest of the function
    }

    // what happens if someone sends ETH to this contract without calling the dun dunction?
    // receive() and fallback() special functions

    // if no calldata is specified, the recieve function is automatically called and forwards the call to the fund function
    receive() external payable {
        fund();
    }

    // if calldata is specified, the fallback function is automatically called and forwards the call to the fund function
    fallback() external payable {
        fund();
    }

    function getVersion() external view returns (uint256) {
        return s_preiceFeed.version();
    }

    function getAddressToAmountFunded(address funder) external view returns (uint256) {
        return s_addressToAmountFunded[funder];
    }

    function getFunder(uint256 index) external view returns (address) {
        return s_funders[index];
    }

    function getOwner() external view returns (address) {
        return i_owner;
    }
}
