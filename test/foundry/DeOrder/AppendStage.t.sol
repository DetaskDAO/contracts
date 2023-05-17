// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "contracts/DeStage.sol";
import {DeOrderTest} from "./DeOrder.t.sol";

contract AppendStage is DeOrderTest {
    uint[] _stageIndexs = [0, 1];

    //testCannotAppendStage
    // @Summary AppendStage fail
    function testCannotAppendStage() public {
        createOrder(issuer, address(0), 100); // create order
        permitStage(worker, issuer, 1, amounts, periods, "Confirm", ""); // permit stage division
        // no on going
        appendStage(issuer, worker, 1, 10, 1000, enFunc("ProgressError()"));
        // on going
        payOrder(issuer, 100, zero); // pay
        startOrder(issuer);
        // empty order id
        appendStage(issuer, worker, 100, 10, 1000, enFunc("ProgressError()"));
        // deadline overtime
        vm.warp(1000002);
        appendStage(issuer, worker, 1, 10, 1000, enFunc("Expired()"));
        vm.warp(0);
        // finish order
        confirmDelivery(issuer, 1, _stageIndexs);
        withdraw(worker, 1, worker);
        appendStage(issuer, worker, 1, 1, 1000, enFunc("ProgressError()"));
    }

    // testAppendStage
    // @Summary AppendStage
    function testAppendStage() public {
        createOrder(issuer, address(0), 100); // create order
        permitStage(worker, issuer, 1, amounts, periods, "Due", ""); // stage division
        payOrder(issuer, 100, zero); // pay
        startOrder(issuer); // start order
        DeStage.Stage[] memory stages0 = deOrder.getStages(1);
        payOrder(issuer, 10, zero); // pay
        appendStage(worker, issuer, 1, 10, 1000, "");
        DeStage.Stage[] memory stages = deOrder.getStages(1);
        assertEq(stages0.length, 2);
        assertEq(stages.length, 3);
        assertEq(stages[2].period, 1000);
        assertEq(stages[2].amount, 10);
    }
}
