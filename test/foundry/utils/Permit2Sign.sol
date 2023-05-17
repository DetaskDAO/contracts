// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import "contracts/DeOrder.sol";
import "contracts/libs/ECDSA.sol";
import "contracts/mock/WETH.sol";

contract Permit2Sign is Test {
    bytes32 public constant _PERMIT_DETAILS_TYPEHASH =
        keccak256(
            "PermitDetails(address token,uint160 amount,uint48 expiration,uint48 nonce)"
        );

    bytes32 public constant _PERMIT_SINGLE_TYPEHASH =
        keccak256(
            "PermitSingle(PermitDetails details,address spender,uint256 sigDeadline)PermitDetails(address token,uint160 amount,uint48 expiration,uint48 nonce)"
        );

    bytes32 public constant _PERMIT_BATCH_TYPEHASH =
        keccak256(
            "PermitBatch(PermitDetails[] details,address spender,uint256 sigDeadline)PermitDetails(address token,uint160 amount,uint48 expiration,uint48 nonce)"
        );

    bytes32 public constant _TOKEN_PERMISSIONS_TYPEHASH =
        keccak256("TokenPermissions(address token,uint256 amount)");

    bytes32 public constant _PERMIT_TRANSFER_FROM_TYPEHASH =
        keccak256(
            "PermitTransferFrom(TokenPermissions permitted,address spender,uint256 nonce,uint256 deadline)TokenPermissions(address token,uint256 amount)"
        );

    bytes32 public constant _PERMIT_BATCH_TRANSFER_FROM_TYPEHASH =
        keccak256(
            "PermitBatchTransferFrom(TokenPermissions[] permitted,address spender,uint256 nonce,uint256 deadline)TokenPermissions(address token,uint256 amount)"
        );

    function defaultERC20PermitTransfer(
        address token0,
        uint256 nonce
    ) internal view returns (IPermit2.PermitTransferFrom memory) {
        return
            IPermit2.PermitTransferFrom({
                permitted: IPermit2.TokenPermissions({
                    token: token0,
                    amount: 10 ** 18
                }),
                nonce: nonce,
                deadline: block.timestamp + 100
            });
    }

    function getTransferDetails(
        address to,
        uint256 amount
    ) private pure returns (IPermit2.SignatureTransferDetails memory) {
        return
            IPermit2.SignatureTransferDetails({
                to: to,
                requestedAmount: amount
            });
    }

    function getPermitTransferSignature(
        IPermit2.PermitTransferFrom memory permit,
        bytes32 domainSeparator,
        address spender
    ) internal pure returns (bytes memory sig) {
        bytes32 tokenPermissions = keccak256(
            abi.encode(_TOKEN_PERMISSIONS_TYPEHASH, permit.permitted)
        );
        bytes32 msgHash = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                keccak256(
                    abi.encode(
                        _PERMIT_TRANSFER_FROM_TYPEHASH,
                        tokenPermissions,
                        spender,
                        permit.nonce,
                        permit.deadline
                    )
                )
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, msgHash);
        return bytes.concat(r, s, bytes1(v));
    }

    // bytes32 DOMAIN_SEPARATOR =
    //     keccak256(
    //         abi.encode(
    //             keccak256(
    //                 "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
    //             ),
    //             keccak256("Permit2"),
    //             block.chainid,
    //             address(permit2)
    //         )
    //     );
}
