// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./libs/ECDSA.sol";
import "./interface/IOrder.sol";

abstract contract DeOrderVerifier {

    error NonceError();
    error Expired();

    bytes32 public DOMAIN_SEPARATOR;
    bytes32 public constant PERMITSTAGE_TYPEHASH = keccak256("PermitStage(uint256 orderId,uint256[] amounts,uint256[] periods,uint256 payType,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMITPROSTAGE_TYPEHASH = keccak256("PermitProStage(uint256 orderId,uint256 stageIndex,uint256 period,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMITAPPENDSTAGE_TYPEHASH = keccak256("PermitAppendStage(uint256 orderId,uint256 amount,uint256 period,uint256 nonce,uint256 deadline)");

    mapping(address => mapping(uint => uint)) public nonces;

    constructor() {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                    keccak256(
                        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                    ),
                    // This should match the domain you set in your client side signing.
                    keccak256(bytes("DetaskOrder")),
                    keccak256(bytes("1")),
                    block.chainid,
                    address(this)
                )
            );
    }


    function recoverPermitStage(uint _orderId, uint[] memory _amounts, uint[] memory _periods,
        uint256 payType,
        uint nonce,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s) internal returns (address signAddr) {
            
            bytes32 structHash  = keccak256(abi.encode(PERMITSTAGE_TYPEHASH, _orderId,
                keccak256(abi.encodePacked(_amounts)), keccak256(abi.encodePacked(_periods)), payType, nonce, deadline));
            return recoverVerify(structHash, _orderId, nonce, deadline, v , r, s);
    }

    function recoverProlongStage(uint _orderId, uint _stageIndex, uint _appendPeriod,
        uint nonce, uint deadline, uint8 v, bytes32 r, bytes32 s) internal returns (address signAddr) {

        bytes32 structHash = keccak256(abi.encode(PERMITPROSTAGE_TYPEHASH, _orderId,
            _stageIndex, _appendPeriod, nonce, deadline));
        return recoverVerify(structHash, _orderId, nonce, deadline, v , r, s);
    }

    function recoverAppendStage(uint _orderId, uint amount, uint period, uint nonce, uint deadline, uint8 v, bytes32 r, bytes32 s) internal returns (address signAddr) {
        bytes32 structHash = keccak256(abi.encode(PERMITAPPENDSTAGE_TYPEHASH, _orderId,
            amount, period, nonce, deadline));
        return recoverVerify(structHash, _orderId, nonce, deadline, v , r, s);

    }

    function recoverVerify(bytes32 structHash, uint _orderId, uint nonce, uint deadline, uint8 v, bytes32 r, bytes32 s) internal returns (address signAddr){
        bytes32 digest = ECDSA.toTypedDataHash(DOMAIN_SEPARATOR, structHash);
        signAddr = ECDSA.recover(digest, v, r, s);

        if(nonces[signAddr][_orderId] != nonce) revert NonceError();
        if(deadline < block.timestamp) revert Expired();
        nonces[signAddr][_orderId] += 1;
    }

} 