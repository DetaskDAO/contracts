//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IOrderVerifier {
    function recoverPermitStage(
        uint256 _orderId,
        uint256[] memory _amounts,
        uint256[] memory _periods,
        uint256 payType,
        uint256 nonce,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (address signAddr);

    function recoverProlongStage(
        uint256 _orderId,
        uint256 _stageIndex,
        uint256 _appendPeriod,
        uint256 nonce,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (address signAddr);

    function recoverAppendStage(
        uint256 _orderId,
        uint256 amount,
        uint256 period,
        uint256 nonce,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (address signAddr);
}
