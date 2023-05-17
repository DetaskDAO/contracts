// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./BytesLib.sol";

library MyStrings {
    using BytesLib for bytes;


    function strlen(string memory s) internal pure returns (uint256 len, uint256 bytelength) {
        uint256 i = 0;
        bytelength = bytes(s).length;

        for (len = 0; i < bytelength; len++) {
            bytes1 b = bytes(s)[i];
            if (b < 0x80) {
                i += 1;
            } else if (b < 0xE0) {
                i += 2;
            } else if (b < 0xF0) {
                i += 3;
            } else if (b < 0xF8) {
                i += 4;
            } else if (b < 0xFC) {
                i += 5;
            } else {
                i += 6;
            }
        }
    }

    function shorten(string memory origin, uint256 maxlength)
        internal
        view
        returns (string memory)
    {
        if (maxlength < 5) return origin;
        bytes memory b = bytes(origin);
        uint256 len = b.length;

        if (len <= maxlength) return origin;

        uint256 kickLength = len - maxlength + 3; // ...

        uint256 mid = (maxlength - 3) / 2;
        uint256 start = (maxlength - 3) / 2;
        if (mid * 2 + 3 != maxlength) {
            start++;
        }
        uint256 end = start + kickLength;

        bytes memory part1 = b.slice(0, start);
        string memory ellipse = "...";
        bytes memory part2 = b.slice(end, len - end);

        return string(abi.encodePacked(string(part1), ellipse, string(part2)));
    }
}
