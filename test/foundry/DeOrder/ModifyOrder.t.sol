// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "contracts/interface/IOrder.sol";
import {DeOrderTest} from "./DeOrder.t.sol";

contract ModifyOrder is DeOrderTest {
    // testCannotModifyOrder
    // @Summary modify Order fail
    function testCannotModifyOrder() public {
        createOrder(issuer, address(0), 100); // create order
        permitStage(issuer, worker, 1, amounts, periods, "Due", ""); // stage division
        // incorrect address
        vm.expectRevert(abi.encodeWithSignature("PermissionsError()"));
        deOrder.modifyOrder(1, address(0), 1);
        // ncorrect address
        payOrder(issuer, 100, zero); // pay
        vm.expectRevert(abi.encodeWithSignature("PermissionsError()"));
        deOrder.modifyOrder(1, address(0), 1);
        // UnSupportToken
        vm.startPrank(issuer); // issuer
        vm.expectRevert(abi.encodeWithSignature("UnSupportToken()"));
        deOrder.modifyOrder(
            1,
            address(0x69BB456f9181C798f6B31149004a5A1ADfAd241B),
            1
        );
        vm.stopPrank();
        // modify ongoing order
        startOrder(issuer); // start order
        vm.startPrank(issuer); // issuer
        vm.expectRevert(abi.encodeWithSignature("ProgressError()"));
        deOrder.modifyOrder(1, issuer, 1);
        vm.stopPrank();
    }

    // testModifyOrder
    // @Summary modify Order
    function testModifyOrder() public {
        Order memory order;
        uint256 balance;

        createOrder(issuer, address(0), 100); // create order
        vm.startPrank(issuer); // issuer
        deOrder.modifyOrder(1, address(0), 1);
        vm.stopPrank();
        order = deOrder.getOrder(1);
        assertEq(order.token, address(0));
        assertEq(order.amount, 1);
        /* change token refund (ETH to Token)
         * @Expect change success
         * @Assert refund amount same
         */
        balance = issuer.balance;
        payOrder(issuer, 100, zero); // pay
        assertEq(balance - 100, issuer.balance); // balance-100
        order = deOrder.getOrder(1);
        vm.startPrank(issuer); // issuer
        vm.stopPrank();
        assertEq(order.payed, 100); 
        assertEq(address(_weth).balance, 100); // weth amount
        setSupportToken(owner, address(token0), true);
        vm.startPrank(issuer); // issuer
        deOrder.modifyOrder(1, address(token0), 1); // modify Order
        vm.stopPrank();
        assertEq(balance, issuer.balance);
        order = deOrder.getOrder(1);
        assertEq(order.token, address(token0));
        assertEq(address(_weth).balance, 0); // weth amount
        assertEq(order.payed, 0); // clear payed
        /* change token refund (Token to ETH)
         * @Expect change success
         * @Assert refund amount same
         */
        balance = token0.balanceOf(issuer);
        vm.startPrank(issuer); // issuer
        // token0.approve(address(deOrder), 100); // approve
        vm.stopPrank();
        payOrder(issuer, 100, address(token0)); // pay
        assertEq(balance - 100, token0.balanceOf(issuer)); // user balance-100
        assertEq(token0.balanceOf(address(deOrder)), 100); // contract balance +100
        order = deOrder.getOrder(1);
        assertEq(order.payed, 100); // pay 100
        vm.startPrank(issuer); // issuer
        deOrder.modifyOrder(1, address(0), 1); // to ETH
        vm.stopPrank();
        assertEq(balance, token0.balanceOf(issuer));
        assertEq(token0.balanceOf(address(deOrder)), 0); // contract balance 0
        order = deOrder.getOrder(1);
        assertEq(order.token, address(0));
        assertEq(order.payed, 0); // clear payed
    }

    /* change token refund not pay (ETH to Token)
     * @Expect change success
     * @Assert not refund 
     */
    function testModifyOrderNotPay() public {
        vm.deal(address(_weth), 1000 ether); // WETH amount
        createOrder(issuer, address(0), 100); // create order
        setSupportToken(owner, address(token0), true);
        modifyOrder(issuer, 1, address(token0), 1);
        assertEq(address(_weth).balance, 1000 ether); // WETH amount
    }
}
