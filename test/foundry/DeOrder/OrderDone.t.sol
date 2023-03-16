// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "contracts/interface/IOrder.sol";
import "forge-std/console2.sol";
import {DeOrderTest} from "./DeOrder.t.sol";

contract OrderDoneTest is DeOrderTest {
    function testDoneOrder() public {
        uint256 balanceOfIssuer = issuer.balance; // issuer amount
        uint256 balanceOfWorker = worker.balance; //
        createOrder(issuer, address(0), 50 ether); // create order
        amounts = [50 ether];
        periods = [1000];
        permitStage(issuer, worker, 1, amounts, periods, "Due", ""); // stage division
        payOrder(issuer, 100 ether, zero); // pay
        assertEq(issuer.balance, balanceOfIssuer - 100 ether);
        assertEq(worker.balance, balanceOfWorker);
        vm.warp(0);
        startOrder(issuer); // start order
        vm.warp(100000);
        withdraw(worker, 1, worker); // withdraw
        refund(issuer, 1, issuer, 50 ether);
        assertEq(issuer.balance, balanceOfIssuer - 50 ether);
        assertEq(worker.balance, balanceOfWorker + 47.5 ether);
    }
}
