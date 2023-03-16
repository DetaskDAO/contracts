// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/console2.sol";
import "contracts/interface/IOrder.sol";
import {DeOrderTest} from "./DeOrder.t.sol";

contract FeeToTest is DeOrderTest {
    function setFeeTo(address who, uint _fee, address _feeTo) public {
        vm.startPrank(who);
        deOrder.setFeeTo(_fee, _feeTo);
        vm.stopPrank();
    }

    function testSetFeeToAbortDone() public {
        // set 1% fee
        assertEq(deOrder.fee(), 500);
        assertEq(deOrder.feeTo(), owner);
        setFeeTo(owner, 100, address(other));
        assertEq(deOrder.fee(), 100);
        assertEq(deOrder.feeTo(), other);
        // abort order
        uint256 balanceOfIssuer = issuer.balance; // issuer amount
        uint256 balanceOfWorker = worker.balance; //
        createOrder(issuer, address(0), 100 ether); // create order
        amounts = [100 ether];
        periods = [86400]; // one day
        permitStage(issuer, worker, 1, amounts, periods, "Due", ""); // stage division
        payOrder(issuer, 100 ether, zero); // pay
        vm.warp(0); //init time
        startOrder(issuer); // start order
        vm.warp(8640); // pass 1/10 days 
        abortOrder(issuer, 1);
        assertEq(issuer.balance, balanceOfIssuer - 10 ether); //order finish issuer amount
        assertEq(worker.balance, balanceOfWorker + 9.9 ether); //order finish worker amount
        assertEq(other.balance, 0.1 ether); //order finish fee receive amount
    }

    function testSetFeeToOrderDone() public {
        // set 1% fee
        assertEq(deOrder.fee(), 500);
        assertEq(deOrder.feeTo(), owner);
        setFeeTo(owner, 100, address(other));
        assertEq(deOrder.fee(), 100);
        assertEq(deOrder.feeTo(), other);
        // order done
        uint256 balanceOfIssuer = issuer.balance; // issuer amount
        uint256 balanceOfWorker = worker.balance; //
        createOrder(issuer, address(0), 100 ether); // create order
        amounts = [100 ether];
        periods = [86400]; // one day
        permitStage(issuer, worker, 1, amounts, periods, "Due", ""); // stage division
        payOrder(issuer, 100 ether, zero); // pay
        vm.warp(0); //init time
        startOrder(issuer); // start order
        vm.warp(864000);
        withdraw(worker, 1, worker);
        assertEq(issuer.balance, balanceOfIssuer - 100 ether); //order finish issuer amount
        assertEq(worker.balance, balanceOfWorker + 99 ether); //order finish worker amount
        assertEq(other.balance, 1 ether); //order finish fee receive amount
    }

    function testSetFeeToAbortDoneALL() public {
        // set 1% fee
        assertEq(deOrder.fee(), 500);
        assertEq(deOrder.feeTo(), owner);
        setFeeTo(owner, 10000, address(other));
        assertEq(deOrder.fee(), 10000);
        assertEq(deOrder.feeTo(), other);
        // abort order
        uint256 balanceOfIssuer = issuer.balance; // issuer amount
        uint256 balanceOfWorker = worker.balance; //
        createOrder(issuer, address(0), 100 ether); // create order
        amounts = [100 ether];
        periods = [86400]; // one day
        permitStage(issuer, worker, 1, amounts, periods, "Due", ""); // stage division
        payOrder(issuer, 100 ether, zero); // pay
        vm.warp(0); //init time
        startOrder(issuer); // start order
        vm.warp(8640); //pass 1/10 days 
        abortOrder(issuer, 1);
        assertEq(issuer.balance, balanceOfIssuer - 10 ether); //order finish issuer amount
        assertEq(worker.balance, balanceOfWorker); //order finish worker amount
        assertEq(other.balance, 10 ether); //order finish fee receive amount
    }

    function testCannotSetFeeTo() public {
        vm.expectRevert("Ownable: caller is not the owner");
        setFeeTo(issuer, 100, address(issuer));
    }
}
