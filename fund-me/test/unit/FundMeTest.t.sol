// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundeMe} from "../../script/DeployFundeMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    modifier funded() {
        vm.prank(USER); // the next tx will be sent by USER
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function setUp() external {
        fundMe = new DeployFundeMe().run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinimumDollarIsFive() public view {
        assertEq(fundMe.MIN_USD(), 5e18, "Minimum USD should be 5");
    }

    function testOwnerIsMsgSender() public view {
        assertEq(fundMe.getOwner(), msg.sender, "Owner should be msg.sender");
    }

    function testFundFailsWithoutEnoughFunds() public {
        vm.expectRevert();
        fundMe.fund();
    }

    function testFundUpdatesFundedDataStructure() public funded {
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE, "Amount funded should be 10");
    }

    function testAddsFunderToArrayOfFunders() public funded {
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER, "Funder should be user");
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        vm.prank(USER); // user is not the owner
        fundMe.withdraw();
    }

    function testWithdrawWithASingleFunder() public funded {
        uint256 ownerBalance = fundMe.getOwner().balance;
        uint256 startingFundBalance = address(fundMe).balance;

        uint256 gasStart = gasleft();
        vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log("Gas used: ", gasUsed);

        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundBalance = address(fundMe).balance;

        assertEq(endingFundBalance, 0, "Fund balance should be 0");
        assertEq(
            ownerBalance + startingFundBalance,
            endingOwnerBalance,
            "Owner balance should be increased"
        );
    }

    function testWithdrawFromMultipleFunders() public {
        uint160 numberOfFunders = 10;
        for (uint160 i = 1; i <= numberOfFunders; i++) {
            hoax(address(i), SEND_VALUE); // does both prank and deal
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 ownerBalance = fundMe.getOwner().balance;
        uint256 startingFundBalance = address(fundMe).balance;

        vm.startPrank(fundMe.getOwner()); // same as prank but can specify when the prank stops
        fundMe.withdraw();
        vm.stopPrank();

        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundBalance = address(fundMe).balance;

        assertEq(endingFundBalance, 0, "Fund balance should be 0");
        assertEq(
            ownerBalance + startingFundBalance,
            endingOwnerBalance,
            "Owner balance should be increased"
        );
    }
}
