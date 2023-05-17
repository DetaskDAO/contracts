pragma solidity ^0.8.4;

library ECDSA {
    error RecoverError(uint season);

    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address signer) {
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
          revert RecoverError(1);  // for InvalidSignatureS
        }
        if (v != 27 && v != 28) {
          revert RecoverError(2);  // for InvalidSignatureV
        }

        // If the signature is valid (and not malleable), return the signer address
        signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
          revert RecoverError(3);  // InvalidSignature
        }
    }

    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }

}