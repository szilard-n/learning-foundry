// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

contract Encoding {
    function combineStrings() public pure returns (string memory) {
        return string(abi.encodePacked("Mi Mom!", "I miss you!"));
    }

    function encodeNumber() public pure returns (bytes memory) {
        bytes memory number = abi.encode(1);
        return number;
    }

    function encodeString() public pure returns (bytes memory) {
        bytes memory someString = abi.encode("some string");
        return someString;
    }

    function encodeStringPacked() public pure returns(bytes memory) {
        return abi.encodePacked("some string");
    }
}
