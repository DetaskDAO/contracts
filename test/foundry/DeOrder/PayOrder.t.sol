// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/console2.sol";
import "contracts/interface/IOrder.sol";
import {IPermit2} from "contracts/interface/IPermit2.sol";
import {DeOrderTest} from "./DeOrder.t.sol";

contract PayOrder is DeOrderTest {
    // testPayOrder
    // @Summary pay
    function testPayOrder() public {
        createOrder(issuer, address(0), 100); // create order
        // pay-ETH
        uint256 balance = issuer.balance; // issuer amount
        uint256 balanceOfWeth = address(_weth).balance; // contract amount
        payOrder(issuer, 100, zero);
        Order memory order = deOrder.getOrder(1);
        assertEq(order.payed, 100);
        assertEq(issuer.balance, balance - 100);
        assertEq(address(_weth).balance, balanceOfWeth + 100);

        // pay-TOKEN
        setSupportToken(owner, address(token0), true);
        modifyOrder(issuer, 1, address(token0), 100);
        uint256 balance2 = token0.balanceOf(issuer); // issuer amount
        uint256 balanceOfWeth2 = token0.balanceOf(address(deOrder)); // contract amount
        payOrder(issuer, 100, address(token0));
        Order memory order2 = deOrder.getOrder(1);
        assertEq(order2.payed, 100);
        assertEq(token0.balanceOf(issuer), balance2 - 100);
        assertEq(token0.balanceOf(address(deOrder)), balanceOfWeth2 + 100);

        // send value not equal amount
        modifyOrder(issuer, 1, address(0), 100);
        uint256 balance3 = issuer.balance; // issuer amount
        uint256 balanceOfWeth3 = address(_weth).balance; // contract amount
        vm.startPrank(issuer);
        deOrder.payOrder{value: 50}(1, 100);
        vm.stopPrank();
        Order memory order3 = deOrder.getOrder(1);
        assertEq(order3.payed, 50);
        assertEq(issuer.balance, balance3 - 50);
        assertEq(address(_weth).balance, balanceOfWeth3 + 50);
    }

    // testCannotPayOrder
    // @Summary pay fail
    function testCannotPayOrder1() public {
        createOrder(issuer, address(0), 100); // create order
        // order-ETH use Token pay
        payOrder(issuer, 100, address(token0));
        Order memory order = deOrder.getOrder(1);
        assertEq(order.payed, 0);
    }

    // testCannotPayOrder
    // @Summary pay fail
    function testCannotPayOrder2() public {
        setSupportToken(owner, address(token0), true);
        createOrder(issuer, address(token0), 100); // create order
        // order-Token use ETH pay
        vm.startPrank(issuer);
        vm.expectRevert(abi.encodeWithSignature("AmountError(uint256)", 0));
        deOrder.payOrder{value: 100}(1, 100);
        vm.stopPrank();
        Order memory order = deOrder.getOrder(1);
        assertEq(order.payed, 0);
    }

    // testCannotPayOrder
    // @Summary pay fail--not exists order
    function testCannotPayOrder3() public {
        vm.startPrank(issuer);
        vm.expectRevert(abi.encodeWithSignature("AmountError(uint256)", 0));
        deOrder.payOrder{value: 100}(1, 100);
        vm.stopPrank();
    }

    // testCannotPayOrder
    // @Summary pay fail3--not exists token
    function testFailPayOrder3() public {
        setSupportToken(
            owner,
            address(0x69BB456f9181C798f6B31149004a5A1ADfAd241B),
            true
        );
        createOrder(
            issuer,
            address(0x69BB456f9181C798f6B31149004a5A1ADfAd241B),
            100
        ); // create order
        // order-ETH use Token pay
        payOrder(
            issuer,
            100,
            address(0x69BB456f9181C798f6B31149004a5A1ADfAd241B)
        );
        Order memory order2 = deOrder.getOrder(1);
        assertEq(order2.payed, 0);
    }

    // testCannotPayOrder
    // @Summary pay fail-- not enougth amount
    function testCannotPayOrder4() public {
        createOrder(issuer, address(0), 100); // create order
        // order-ETH use Token pay
        payOrder(worker, 100, address(token0));
        Order memory order = deOrder.getOrder(1);
        assertEq(order.payed, 0);
    }

    // testCannotPayOrder
    // @Summary pay fail-- not enougth amount 
    function testFailPayOrder5() public {
        setSupportToken(owner, address(token0), true);
        createOrder(issuer, address(token0), 100); // create order
        payOrder(worker, 100, address(token0));
        Order memory order = deOrder.getOrder(1);
        assertEq(order.payed, 0);
    }

    // testPayOrderWithPermit2
    // @Summary Permit2 pay
    function testPayOrderWithPermit2() public {
        setSupportToken(owner, address(token0), true);
        createOrder(issuer, address(token0), 100); // create order
        permitStage(worker, issuer, 1, amounts, periods, "Confirm", ""); // normal permitStage
        // pay-TOKEN
        uint256 balance = token0.balanceOf(issuer); // issuer amount
        uint256 balanceOfDeOrder = token0.balanceOf(address(deOrder)); // contract amount
        payOrderWithPermit2(issuer, 1, 100, address(token0));
        Order memory order = deOrder.getOrder(1);
        assertEq(order.payed, 100);
        assertEq(token0.balanceOf(issuer), balance - 100);
        assertEq(token0.balanceOf(address(deOrder)), balanceOfDeOrder + 100);
    }
}
