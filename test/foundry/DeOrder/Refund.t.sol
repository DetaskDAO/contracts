// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {DeOrderTest} from "./DeOrder.t.sol";
import "contracts/interface/IOrder.sol";
import "forge-std/console2.sol";

contract Refund is DeOrderTest {
    uint[] _stageIndexs = [0];

    // Due out of time and normal refund
    function testDueRefundByTimeOutGetNormal() public {
        vm.deal(owner, 0 ether); // init eth balance
        //create order stage division
        createOrder(issuer, address(0), 100 ether); // create order
        amounts = [100 ether]; //100
        periods = [172800]; // two day
        permitStage(issuer, worker, 1, amounts, periods, "Due", ""); // stage division

        vm.expectRevert(abi.encodeWithSignature("PermissionsError()"));
        refund(worker, 1, issuer, 100 ether);
        vm.expectRevert(abi.encodeWithSignature("PermissionsError()"));
        refund(other, 1, issuer, 100 ether);

        payOrder(issuer, 200 ether, zero); // pay

        // before start issuer, worker, other to refund
        refund(issuer, 1, issuer, 100 ether); // issuer refund
        payOrder(issuer, 100 ether, zero); // pay
        vm.expectRevert(abi.encodeWithSignature("PermissionsError()"));
        refund(worker, 1, issuer, 100 ether);
        vm.expectRevert(abi.encodeWithSignature("PermissionsError()"));
        refund(other, 1, issuer, 100 ether);
        assertEq(address(issuer).balance, 800 ether); // issuer amount

        // order start
        vm.warp(0); //init time
        startOrder(issuer); // start order
        vm.warp(100);

        // order ongoing
        vm.expectRevert(abi.encodeWithSignature("PermissionsError()"));
        refund(worker, 1, issuer, 100 ether);
        vm.expectRevert(abi.encodeWithSignature("PermissionsError()"));
        refund(other, 1, issuer, 100 ether);
        refund(issuer, 1, issuer, 100 ether);
        payOrder(issuer, 100 ether, zero); // pay
        assertEq(address(issuer).balance, 800 ether);
        // order prolong
        prolongStage(issuer, worker, 1, 0, 1000, "");
        vm.expectRevert(abi.encodeWithSignature("PermissionsError()"));
        refund(worker, 1, issuer, 100 ether);
        vm.expectRevert(abi.encodeWithSignature("PermissionsError()"));
        refund(other, 1, issuer, 100 ether);
        refund(issuer, 1, issuer, 100 ether);
        vm.expectRevert(abi.encodeWithSignature("AmountError(uint256)", 1)); // called multiple
        refund(issuer, 1, issuer, 100 ether);
        payOrder(issuer, 100 ether, zero); // pay
        assertEq(address(issuer).balance, 800 ether);
        // increase stage
        appendStage(issuer, worker, 1, 100 ether, 4000, "");
        payOrder(issuer, 100 ether, zero); // pay
        vm.warp(100000);
        vm.expectRevert(abi.encodeWithSignature("PermissionsError()"));
        refund(worker, 1, issuer, 100 ether);
        vm.expectRevert(abi.encodeWithSignature("PermissionsError()"));
        refund(other, 1, issuer, 100 ether);
        refund(issuer, 1, issuer, 100 ether);
        vm.expectRevert(abi.encodeWithSignature("AmountError(uint256)", 1)); // called multiple
        refund(issuer, 1, issuer, 100 ether);
        payOrder(issuer, 100 ether, zero); // pay
        assertEq(address(issuer).balance, 700 ether);
        // order done
        vm.warp(1728000);
        vm.expectRevert(abi.encodeWithSignature("PermissionsError()"));
        refund(worker, 1, issuer, 100 ether);
        vm.expectRevert(abi.encodeWithSignature("PermissionsError()"));
        refund(other, 1, issuer, 100 ether);
        refund(issuer, 1, issuer, 100 ether);
        vm.expectRevert(abi.encodeWithSignature("AmountError(uint256)", 1)); // called multiple
        refund(issuer, 1, issuer, 100 ether);
        assertEq(address(issuer).balance, 800 ether);
        assertEq(address(_weth).balance, 200 ether);

        // console2.log(address(issuer).balance);
        // console2.log(address(worker).balance);
        // console2.log(address(_weth).balance);
        // console2.log(address(owner).balance);
    }

    function testConfirmRefundByTimeOutGetNormal() public {
        vm.deal(owner, 0 ether); // init eth balance
        createOrder(issuer, address(0), 100 ether); // create order
        amounts = [100 ether]; //100
        periods = [172800]; // two day
        permitStage(issuer, worker, 1, amounts, periods, "Confirm", ""); // stage division

        payOrder(issuer, 200 ether, zero); // pay

        // order start
        vm.warp(0); //init time
        startOrder(issuer); // start order
        vm.warp(100);

        // order ongoing
        vm.expectRevert(abi.encodeWithSignature("PermissionsError()"));
        refund(worker, 1, issuer, 100 ether);
        vm.expectRevert(abi.encodeWithSignature("PermissionsError()"));
        refund(other, 1, issuer, 100 ether);
        refund(issuer, 1, issuer, 100 ether);
        payOrder(issuer, 100 ether, zero); // pay
        assertEq(address(issuer).balance, 800 ether);
        // order prolong
        prolongStage(issuer, worker, 1, 0, 1000, "");
        vm.expectRevert(abi.encodeWithSignature("PermissionsError()"));
        refund(worker, 1, issuer, 100 ether);
        vm.expectRevert(abi.encodeWithSignature("PermissionsError()"));
        refund(other, 1, issuer, 100 ether);
        refund(issuer, 1, issuer, 100 ether);
        vm.expectRevert(abi.encodeWithSignature("AmountError(uint256)", 1)); // called multiple
        refund(issuer, 1, issuer, 100 ether);
        payOrder(issuer, 100 ether, zero); // pay
        assertEq(address(issuer).balance, 800 ether);
        //increase stage
        appendStage(issuer, worker, 1, 100, 4000, "");
        payOrder(issuer, 100 ether, zero); // pay
        vm.warp(100000);
        vm.expectRevert(abi.encodeWithSignature("PermissionsError()"));
        refund(worker, 1, issuer, 100 ether);
        vm.expectRevert(abi.encodeWithSignature("PermissionsError()"));
        refund(other, 1, issuer, 100 ether);
        refund(issuer, 1, issuer, 100 ether);
        vm.expectRevert(abi.encodeWithSignature("AmountError(uint256)", 1)); // called multiple
        refund(issuer, 1, issuer, 100 ether);
        payOrder(issuer, 100 ether, zero); // pay
        assertEq(address(issuer).balance, 700 ether);

        stageIndexs = [0];
        confirmDelivery(issuer, 1, stageIndexs);
        vm.warp(100000);
        // order done
        vm.expectRevert(abi.encodeWithSignature("PermissionsError()"));
        refund(worker, 1, issuer, 100 ether);
        vm.expectRevert(abi.encodeWithSignature("PermissionsError()"));
        refund(other, 1, issuer, 100 ether);
        refund(issuer, 1, issuer, 100 ether);
        vm.expectRevert(abi.encodeWithSignature("AmountError(uint256)", 1)); // called multiple
        refund(issuer, 1, issuer, 100 ether);
        assertEq(address(issuer).balance, 800 ether);
        assertEq(address(_weth).balance, 200 ether);
        payOrder(issuer, 100 ether, zero); // pay
        stageIndexs = [1];
        confirmDelivery(issuer, 1, stageIndexs);
        vm.expectRevert(abi.encodeWithSignature("PermissionsError()"));
        refund(worker, 1, issuer, 100 ether);
        vm.expectRevert(abi.encodeWithSignature("PermissionsError()"));
        refund(other, 1, issuer, 100 ether);
        refund(issuer, 1, issuer, 100 ether);
        vm.expectRevert(abi.encodeWithSignature("AmountError(uint256)", 1)); // called multiple
        refund(issuer, 1, issuer, 100 ether);
        assertEq(address(issuer).balance, 800 ether);
        assertEq(address(_weth).balance, 200 ether);

        // console2.log(address(issuer).balance);
        // console2.log(address(worker).balance);
        // console2.log(address(_weth).balance);
        // console2.log(address(owner).balance);
    }

    // order abort and refund
    function testDueissuerAbortOrderrefund() public {
        vm.deal(owner, 0 ether); // init eth balance
        createOrder(issuer, address(0), 100 ether); // create order
        amounts = [100 ether]; //100
        periods = [172800]; // two day
        permitStage(issuer, worker, 1, amounts, periods, "Due", ""); // stage division

        payOrder(issuer, 200 ether, zero); // pay
        vm.warp(0); //init time
        startOrder(issuer); // start order
        vm.warp(86400);
        abortOrder(issuer, 1);
        vm.expectRevert(abi.encodeWithSignature("PermissionsError()"));
        refund(worker, 1, issuer, 100 ether);
        vm.expectRevert(abi.encodeWithSignature("PermissionsError()"));
        refund(other, 1, issuer, 100 ether);
        // console2.log(address(issuer).balance);
        // console2.log(address(worker).balance);
        // console2.log(address(_weth).balance);
        // console2.log(address(owner).balance);
        refund(issuer, 1, issuer, 100 ether);
        vm.expectRevert(abi.encodeWithSignature("AmountError(uint256)", 1)); // called multiple
        refund(issuer, 1, issuer, 100 ether);
    }

    function testConfirmIssuerAbortOrderrefund() public {
        vm.deal(owner, 0 ether); // init eth balance
        createOrder(issuer, address(0), 100 ether); // create order
        amounts = [100 ether]; //100
        periods = [172800]; // two day
        permitStage(issuer, worker, 1, amounts, periods, "Confirm", ""); // stage division

        payOrder(issuer, 200 ether, zero); // pay
        vm.warp(0); //init time
        startOrder(issuer); // start order
        vm.warp(86400);
        abortOrder(issuer, 1);
        vm.expectRevert(abi.encodeWithSignature("PermissionsError()"));
        refund(worker, 1, issuer, 100 ether);
        vm.expectRevert(abi.encodeWithSignature("PermissionsError()"));
        refund(other, 1, issuer, 100 ether);
        // console2.log(address(issuer).balance);
        // console2.log(address(worker).balance);
        // console2.log(address(_weth).balance);
        // console2.log(address(owner).balance);
        refund(issuer, 1, issuer, 100 ether);
        vm.expectRevert(abi.encodeWithSignature("AmountError(uint256)", 1)); // called multiple
        refund(issuer, 1, issuer, 100 ether);
    }

    // order permit stage and issuer refund
    function testFailDueRefundByTimeOutGetNormal() public {
        vm.deal(owner, 0 ether); // init eth balance
        createOrder(issuer, address(0), 100 ether); // create order
        amounts = [100 ether]; //100
        periods = [172800]; // two day
        permitStage(issuer, worker, 1, amounts, periods, "Due", ""); // stage division
        refund(issuer, 1, issuer, 100 ether);
    }

    // refund all stage 
    function testRefundGreaterOrder() public {
        vm.deal(owner, 0 ether); // init eth balance
        createOrder(issuer, address(0), 100 ether); // create order

        amounts = [100 ether]; //100
        periods = [172800]; // two day
        permitStage(issuer, worker, 1, amounts, periods, "Due", ""); // stage division

        payOrder(issuer, 200 ether, zero); // pay

        // refund(issuer, 1, issuer, 120 ether);
        // assertEq(address(issuer).balance, 800 ether); // issuer amount

        // order start
        vm.warp(0); //init time
        startOrder(issuer); // start order

        // more than payed
        vm.expectRevert(abi.encodeWithSignature("AmountError(uint256)", 1)); // called multiple
        refund(issuer, 1, issuer, 150 ether);
        // order ongoing
        // refund(issuer, 1, issuer, 100 ether);
        // payOrder(issuer, 100 ether, zero); // pay
        // assertEq(address(issuer).balance, 800 ether);
        //order prolong
        prolongStage(issuer, worker, 1, 0, 1000, "");
        vm.expectRevert(abi.encodeWithSignature("AmountError(uint256)", 1)); // called multiple
        refund(issuer, 1, issuer, 150 ether);

        assertEq(address(issuer).balance, 800 ether);
        // increase stage
        appendStage(issuer, worker, 1, 100, 4000, "");
        payOrder(issuer, 100 ether, zero); // pay
        vm.warp(100000);
        vm.expectRevert(abi.encodeWithSignature("AmountError(uint256)", 1)); // called multiple
        refund(issuer, 1, issuer, 200 ether);
        assertEq(address(issuer).balance, 700 ether);
    }

    function testRefundNotStartOrder() public {
        uint256 balance = issuer.balance; // issuer amount
        createOrder(issuer, zero, 100);
        assertEq(_weth.totalSupply(), 0);
        payOrder(issuer, 100, zero);
        assertEq(_weth.totalSupply(), 100);
        assertEq(issuer.balance, balance - 100);
        refund(issuer, 1, issuer, 100);
        assertEq(_weth.totalSupply(), 0);
        assertEq(issuer.balance, balance);
    }

    function testRefundNotStartOrder2() public {
        uint256 balance = issuer.balance; // issuer amount
        createOrder(issuer, zero, 100);
        assertEq(_weth.totalSupply(), 0);
        payOrder(issuer, 100, zero);
        assertEq(_weth.totalSupply(), 100);
        assertEq(issuer.balance, balance - 100);
        refund(issuer, 1, address(issuer), 100);
        assertEq(_weth.totalSupply(), 0);
        assertEq(issuer.balance, balance);
    }
}
