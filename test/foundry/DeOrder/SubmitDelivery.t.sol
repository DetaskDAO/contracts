// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {DeOrderTest} from "./DeOrder.t.sol";

contract SubmitDelivery is DeOrderTest {
    // submit delivery
    // @Summary SubmitDelivery
    function submitDelivery() public {
        createOrder(issuer, address(0), 100); // create order
        permitStage(worker, issuer, 1, amounts, periods, "Confirm", ""); // permit stage division
        payOrder(issuer, 100, zero); // pay
        startOrder(issuer); // start order
        vm.startPrank(worker); // worker
        deOrder.updateAttachment(1, "ok");
        vm.stopPrank();
    }

    // submit delivery
    // @Summary SubmitDelivery fail
    function testCannotSubmitDelivery() public {
        createOrder(issuer, address(0), 100); // create order
        permitStage(worker, issuer, 1, amounts, periods, "Confirm", ""); // permit stage division
        payOrder(issuer, 100, zero); // pay
        startOrder(issuer); // start order
        vm.expectRevert(abi.encodeWithSignature("PermissionsError()"));
        deOrder.updateAttachment(1, "ok");
    }
}
