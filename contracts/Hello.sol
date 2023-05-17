//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Hello {
    uint public value = 10;

    function setVaule(uint256 x) public {
        value = x;
    }
}