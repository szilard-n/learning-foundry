// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

contract CallAnything {
    address public s_someAddress;
    uint256 public s_amount;

    function transfer(address someAddress, uint256 someAmount) public {
        s_someAddress = someAddress;
        s_amount = someAmount;
    }

    function getSelectorOne() public pure returns (bytes4 selector) {
        return bytes4(keccak256("transfer(address,uint256)"));
    }

    function getDataToCallTransfer(address someAddress, uint256 someAmount)
        public
        pure
        returns (bytes memory data)
    {
        return
            abi.encodeWithSelector(getSelectorOne(), someAddress, someAmount);
    }

    function callTransferFunctionDirectly(
        address someAddress,
        uint256 someAmount
    ) public returns (bytes4, bool) {
        (bool success, bytes memory returnData) = address(this).call(
            abi.encodeWithSelector(getSelectorOne(), someAddress, someAmount)
        );
        return (bytes4(returnData), success);
    }
}
