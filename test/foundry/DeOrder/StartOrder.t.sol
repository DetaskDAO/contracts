// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "contracts/DeStage.sol";
import "contracts/interface/IOrder.sol";
import {DeOrderTest} from "./DeOrder.t.sol";

contract StartOrder is DeOrderTest {
    // testCannotStartOrder
    // @Summary start order
    function testCannotStartOrder() public {
        createOrder(issuer, address(0), 100); // create order
        // stage division not finish
        vm.expectRevert(abi.encodeWithSignature("ProgressError()"));
        startOrder(issuer);
        permitStage(issuer, worker, 1, amounts, periods, "Due", ""); // stage division
        // no pay
        vm.expectRevert(abi.encodeWithSignature("AmountError(uint256)", 1));
        startOrder(issuer);
        // order Amount not equal stage Amount 
        vm.startPrank(issuer);
        deOrder.modifyOrder(1, address(0), 1);
        vm.stopPrank();
        vm.expectRevert(abi.encodeWithSignature("AmountError(uint256)", 0));
        startOrder(issuer);
    }
    // testStartOrder
    // @Summary start order
    function testStartOrder() public {
        createOrder(issuer, address(0), 100); // create order
        permitStage(issuer, worker, 1, amounts, periods, "Due", ""); // stage division
        payOrder(issuer, 100, zero); // pay
        // issuer
        startOrder(issuer);
        Order memory order = deOrder.getOrder(1);
        DeStage.Stage[] memory stages = deOrder.getStages(1);
        assert(order.progress == OrderProgess.Ongoing);
        assert(stages[0].status == DeStage.StageStatus.Init);
    }
}
