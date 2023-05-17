// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "forge-std/Test.sol";
import "forge-std/console2.sol";

contract BitMapTest is Test {
    mapping(address => mapping(uint256 => uint256)) public nonceBitmap;
    address owner; // owner
    error InvalidNonce();

    function setUp() public {
        owner = msg.sender;
    }

    /// @notice Returns the index of the bitmap and the bit position within the bitmap. Used for unordered nonces
    /// @param nonce The to get the associated word and bit positions
    /// @return wordPos The word position or index into the nonceBitmap
    /// @return bitPos The bit position
    /// @dev The first 248 bits of the nonce value is the index of the desired bitmap
    /// @dev The last 8 bits of the nonce value is the position of the bit in the bitmap
    function bitmapPositions(uint256 nonce)
        private
        view
        returns (uint256 wordPos, uint256 bitPos)
    {
        wordPos = uint248(nonce >> 8);
        bitPos = uint8(nonce);

        console2.log("wordPos");
        console2.log(wordPos);
        console2.log("bitPos");
        console2.log(bitPos);
    }

    /// @notice Checks whether a nonce is taken and sets the bit at the bit position in the bitmap at the word position
    /// @param from The address to use the nonce at
    /// @param nonce The nonce to spend
    function _useUnorderedNonce(address from, uint256 nonce) internal {
        (uint256 wordPos, uint256 bitPos) = bitmapPositions(nonce);
        uint256 bit = 1 << bitPos;
        console2.log("bit");
        console2.log(bit);
        console2.log("nonceBitmap[from][wordPos]");
        console2.log(nonceBitmap[from][wordPos]);
        uint256 flipped = nonceBitmap[from][wordPos] ^= bit;
        console2.log("flipped");
        console2.log(flipped);

        if (flipped & bit == 0) revert InvalidNonce();
    }

    function testBitMap() public {
        _useUnorderedNonce(owner, 1);
        _useUnorderedNonce(owner, 2);
        _useUnorderedNonce(owner, 3);
    }
}
