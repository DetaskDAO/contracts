// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/Test.sol";

contract Utilities is Test {
    function isStringEmpty(string memory _test) public pure returns (bool) {
        bytes memory checkString = bytes(_test);
        if (checkString.length > 0) {
            return false;
        } else {
            return true;
        }
    }

    function enFunc(
        string memory funcString
    ) public pure returns (bytes memory res) {
        if (!isStringEmpty(funcString)) {
            res = abi.encodeWithSignature(funcString);
        }
        return res;
    }

    
}
