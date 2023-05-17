// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "contracts/DeStage.sol";
import "contracts/libs/ECDSA.sol";
import {DeOrderTest} from "./DeOrder.t.sol";

contract ProlongStage is DeOrderTest {
    uint[] _stageIndexs = [0, 1];

    // testCannotProlongStage
    // @Summary ProlongStage fail
    function testCannotProlongStage() public {
        createOrder(issuer, address(0), 100); // create order
        permitStage(worker, issuer, 1, amounts, periods, "Confirm", ""); // permit stage division
        // not ongoing
        prolongStage(worker, issuer, 1,1, 1000, enFunc("ProgressError()"));
        // ongoing
        payOrder(issuer, 100, zero); // pay
        startOrder(issuer);
        // orderID invalid
        prolongStage(issuer, worker, 100, 1, 1000, enFunc("ProgressError()"));
        // deadline expired
        vm.warp(1000002);
        prolongStage(issuer, worker, 1,1,1000, enFunc("Expired()"));
        vm.warp(0);
        // order done
        confirmDelivery(issuer, 1, _stageIndexs);
        withdraw(worker, 1, worker);
        prolongStage(issuer, worker, 1, 1, 1000, enFunc("ProgressError()"));
    }

    function testFailProlongStage() public {
        createOrder(issuer, address(0), 100); // create order
        permitStage(worker, issuer, 1, amounts, periods, "Confirm", ""); // permit stage division
        payOrder(issuer, 100, zero); // pay
        startOrder(issuer);
        prolongStage(worker, issuer, 1, 1, 1000, "Index out of bounds");
    }

    // testProlongStage
    // @Summary ProlongStage
    function testProlongStage() public {
        createOrder(issuer, address(0), 100); // create order
        permitStage(worker, issuer, 1, amounts, periods, "Due", ""); // stage division
        payOrder(issuer, 100, zero); // pay
        startOrder(issuer); // start order
        DeStage.Stage[] memory stages0 = deOrder.getStages(1);
        prolongStage(issuer, worker, 1, 1, 1000, "");
        DeStage.Stage[] memory stages = deOrder.getStages(1);
        assertEq(stages0[0].period, stages[0].period);
        assertEq(stages0[1].period + 1000, stages[1].period);
    }
}
