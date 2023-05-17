// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test, stdJson, console2} from "forge-std/Test.sol";
import {ISignatureTransfer} from "permit2/interfaces/ISignatureTransfer.sol";
import {Permit2} from "permit2/Permit2.sol";
import {IAllowanceTransfer} from "permit2/interfaces/IAllowanceTransfer.sol";
import {ISignatureTransfer} from "permit2/interfaces/ISignatureTransfer.sol";
import {PermitHash} from "permit2/libraries/PermitHash.sol";
import {MockERC20} from "./mock/MockERC20.sol";

contract Permit2Test is Test {
    Permit2 permit2;
    address from;
    uint256 fromPrivateKey;
    uint256 defaultAmount = 1 ** 18;

    address address0 = address(0x0);
    address address2 = address(0x2);

    bytes32 DOMAIN_SEPARATOR;

    MockERC20 token0;

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

    function setUp() public {
        permit2 = new Permit2();
        DOMAIN_SEPARATOR = permit2.DOMAIN_SEPARATOR();

        fromPrivateKey = 0x12341234;
        from = vm.addr(fromPrivateKey);

        token0 = new MockERC20("Test0", "TEST0", 18);
        token0.mint(from, 100 ** 18);
        vm.startPrank(from);
        token0.approve(address(permit2), type(uint256).max);
        vm.stopPrank();
    }

    function getTransferDetails(
        address to,
        uint256 amount
    )
        private
        pure
        returns (ISignatureTransfer.SignatureTransferDetails memory)
    {
        return
            ISignatureTransfer.SignatureTransferDetails({
                to: to,
                requestedAmount: amount
            });
    }

    function getPermitTransferSignature(
        ISignatureTransfer.PermitTransferFrom memory permit,
        uint256 privateKey,
        bytes32 domainSeparator
    ) internal view returns (bytes memory sig) {
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
                        address(this),
                        permit.nonce,
                        permit.deadline
                    )
                )
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, msgHash);
        return bytes.concat(r, s, bytes1(v));
    }

    function defaultERC20PermitTransfer(
        address tokenAddr,
        uint256 nonce
    ) internal view returns (ISignatureTransfer.PermitTransferFrom memory) {
        return
            ISignatureTransfer.PermitTransferFrom({
                permitted: ISignatureTransfer.TokenPermissions({
                    token: tokenAddr,
                    amount: 10 ** 18
                }),
                nonce: nonce,
                deadline: block.timestamp + 100
            });
    }

    event printDetail(
        ISignatureTransfer.PermitTransferFrom permit,
        ISignatureTransfer.SignatureTransferDetails transferDetails,
        address from,
        bytes sig
    );

    function testPermitTransferFrom() public {
        uint256 nonce = 0;
        ISignatureTransfer.PermitTransferFrom
            memory permit = defaultERC20PermitTransfer(address(token0), nonce);
        bytes memory sig = getPermitTransferSignature(
            permit,
            fromPrivateKey,
            DOMAIN_SEPARATOR
        );

        uint256 startBalanceFrom = token0.balanceOf(from);
        uint256 startBalanceTo = token0.balanceOf(address2);

        ISignatureTransfer.SignatureTransferDetails
            memory transferDetails = getTransferDetails(
                address2,
                defaultAmount
            );
        emit printDetail(permit, transferDetails, from, sig);
        permit2.permitTransferFrom(permit, transferDetails, from, sig);
        assertEq(token0.balanceOf(from), startBalanceFrom - defaultAmount);
        assertEq(token0.balanceOf(address2), startBalanceTo + defaultAmount);
    }
}
