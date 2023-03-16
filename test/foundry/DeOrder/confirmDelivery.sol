// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "contracts/interface/IOrder.sol";
import "forge-std/console2.sol";
import {DeOrderTest} from "./DeOrder.t.sol";

contract confirmDelivery is DeOrderTest {
    //Due
    function testDue() public {
        vm.deal(owner, 0 ether); // init eth balance
        createOrder(issuer, zero, 100 ether);
        // Undivided stage confirmDelivery
        vm.expectRevert(abi.encodeWithSignature("ProgressError()"));
        stageIndexs = [0];
        confirmDelivery(issuer, 1, stageIndexs);
        vm.expectRevert(abi.encodeWithSignature("ProgressError()"));
        confirmDelivery(zero, 1, stageIndexs);
        vm.expectRevert(abi.encodeWithSignature("ProgressError()"));
        confirmDelivery(worker, 1, stageIndexs);
        vm.expectRevert(abi.encodeWithSignature("ProgressError()"));
        confirmDelivery(other, 1, stageIndexs);

        amounts = [100 ether]; //100
        periods = [172800]; // two day
        permitStage(issuer, worker, 1, amounts, periods, "Due", ""); // stage division

        // order not start confirmDelivery
        vm.expectRevert(abi.encodeWithSignature("ProgressError()"));
        stageIndexs = [0];
        confirmDelivery(issuer, 1, stageIndexs);
        vm.expectRevert(abi.encodeWithSignature("ProgressError()"));
        confirmDelivery(worker, 1, stageIndexs);
        vm.expectRevert(abi.encodeWithSignature("ProgressError()"));
        confirmDelivery(other, 1, stageIndexs);

        // pay
        payOrder(issuer, 100 ether, zero);

        vm.expectRevert(abi.encodeWithSignature("ProgressError()"));
        stageIndexs = [0];
        confirmDelivery(issuer, 1, stageIndexs);
        vm.expectRevert(abi.encodeWithSignature("ProgressError()"));
        confirmDelivery(worker, 1, stageIndexs);
        vm.expectRevert(abi.encodeWithSignature("ProgressError()"));
        confirmDelivery(other, 1, stageIndexs);

        vm.warp(0); //init time
        startOrder(issuer); // start order
        vm.warp(86400);
        //

        stageIndexs = [0];

        vm.expectRevert(abi.encodeWithSignature("PermissionsError()"));
        confirmDelivery(worker, 1, stageIndexs);
        vm.expectRevert(abi.encodeWithSignature("PermissionsError()"));
        confirmDelivery(other, 1, stageIndexs);
        confirmDelivery(issuer, 1, stageIndexs);
        vm.expectRevert(abi.encodeWithSignature("AmountError(uint256)", 1));
        refund(issuer, 1, issuer, 1 ether);
        withdraw(worker, 1, worker);
        assertEq(address(worker).balance, 95 ether);
        console2.log(address(issuer).balance);
        console2.log(address(worker).balance);
        console2.log(address(_weth).balance);
        console2.log(address(owner).balance);
    }

    function testConfirm() public {
        vm.deal(owner, 0 ether); // init eth balance
        createOrder(issuer, zero, 100 ether);

        amounts = [100 ether]; //100
        periods = [172800]; // two day
        permitStage(issuer, worker, 1, amounts, periods, "Confirm", ""); // stage division

        // order not start confirmDelivery
        vm.expectRevert(abi.encodeWithSignature("ProgressError()"));
        stageIndexs = [0];
        confirmDelivery(issuer, 1, stageIndexs);
        vm.expectRevert(abi.encodeWithSignature("ProgressError()"));
        confirmDelivery(worker, 1, stageIndexs);
        vm.expectRevert(abi.encodeWithSignature("ProgressError()"));
        confirmDelivery(other, 1, stageIndexs);

        // pay
        payOrder(issuer, 100 ether, zero);

        vm.expectRevert(abi.encodeWithSignature("ProgressError()"));
        stageIndexs = [0];
        confirmDelivery(issuer, 1, stageIndexs);
        vm.expectRevert(abi.encodeWithSignature("ProgressError()"));
        confirmDelivery(worker, 1, stageIndexs);
        vm.expectRevert(abi.encodeWithSignature("ProgressError()"));
        confirmDelivery(other, 1, stageIndexs);

        vm.warp(0); //init time
        startOrder(issuer); // start order
        vm.warp(864000);
        //
        stageIndexs = [0];
        vm.expectRevert(abi.encodeWithSignature("PermissionsError()"));
        confirmDelivery(worker, 1, stageIndexs);
        vm.expectRevert(abi.encodeWithSignature("PermissionsError()"));
        confirmDelivery(other, 1, stageIndexs);

        confirmDelivery(issuer, 1, stageIndexs);
        vm.expectRevert(abi.encodeWithSignature("AmountError(uint256)", 1));
        refund(issuer, 1, issuer, 1 ether);
        withdraw(worker, 1, worker);
        assertEq(address(worker).balance, 95 ether);
        // console2.log(address(issuer).balance);
        // console2.log(address(worker).balance);
        // console2.log(address(_weth).balance);
        // console2.log(address(owner).balance);
    }

    function testDueAppendStage() public {
        vm.deal(owner, 0 ether); // init eth balance
        createOrder(issuer, zero, 100 ether);
        amounts = [100 ether]; //100
        periods = [172800]; // two day
        permitStage(issuer, worker, 1, amounts, periods, "Due", ""); // stage division
        payOrder(issuer, 100 ether, zero);
        vm.warp(0); //init time
        startOrder(issuer); // start order
        payOrder(issuer, 100 ether, zero);
        appendStage(issuer, worker, 1, 100 ether, 86400, "");

        // confirm first stage
        vm.warp(182800);
        vm.expectRevert(abi.encodeWithSignature("PermissionsError()"));
        confirmDelivery(worker, 1, stageIndexs);
        vm.expectRevert(abi.encodeWithSignature("PermissionsError()"));
        confirmDelivery(other, 1, stageIndexs);
        stageIndexs = [0];
        confirmDelivery(issuer, 1, stageIndexs);
        vm.expectRevert(abi.encodeWithSignature("AmountError(uint256)", 1));
        refund(issuer, 1, issuer, 1 ether);
        assertEq(address(issuer).balance, 800 ether);
        withdraw(worker, 1, worker);
        assertEq(address(worker).balance, 95 ether);

        // confirm second stage
        vm.warp(1828000);
        vm.expectRevert(abi.encodeWithSignature("PermissionsError()"));
        confirmDelivery(worker, 1, stageIndexs);
        vm.expectRevert(abi.encodeWithSignature("PermissionsError()"));
        confirmDelivery(other, 1, stageIndexs);
        stageIndexs = [1];
        confirmDelivery(issuer, 1, stageIndexs);
        vm.expectRevert(abi.encodeWithSignature("AmountError(uint256)", 1));
        refund(issuer, 1, issuer, 1 ether);
        assertEq(address(issuer).balance, 800 ether);
        withdraw(worker, 1, worker);
        assertEq(address(worker).balance, 190 ether);
        console2.log(address(issuer).balance);
        console2.log(address(worker).balance);
        console2.log(address(_weth).balance);
        console2.log(address(owner).balance);
    }

    function testConfirmAppendStage() public {
        vm.deal(owner, 0 ether); // init eth balance
        createOrder(issuer, zero, 100 ether);
        amounts = [100 ether]; //100
        periods = [172800]; // two day
        permitStage(issuer, worker, 1, amounts, periods, "Confirm", ""); // stage division
        payOrder(issuer, 100 ether, zero);
        vm.warp(0); //init time
        startOrder(issuer); // start order
        payOrder(issuer, 100 ether, zero);
        appendStage(issuer, worker, 1, 100 ether, 86400, "");

        // confirm first stage
        vm.warp(182800);
        stageIndexs = [0];
        vm.expectRevert(abi.encodeWithSignature("PermissionsError()"));
        confirmDelivery(worker, 1, stageIndexs);
        vm.expectRevert(abi.encodeWithSignature("PermissionsError()"));
        confirmDelivery(other, 1, stageIndexs);

        confirmDelivery(issuer, 1, stageIndexs);
        vm.expectRevert(abi.encodeWithSignature("AmountError(uint256)", 1));
        refund(issuer, 1, issuer, 1 ether);
        assertEq(address(issuer).balance, 800 ether);
        withdraw(worker, 1, worker);
        assertEq(address(worker).balance, 95 ether);

        // confirm second stage
        vm.warp(1828000);
        stageIndexs = [1];
        vm.expectRevert(abi.encodeWithSignature("PermissionsError()"));
        confirmDelivery(worker, 1, stageIndexs);
        vm.expectRevert(abi.encodeWithSignature("PermissionsError()"));
        confirmDelivery(other, 1, stageIndexs);
        confirmDelivery(issuer, 1, stageIndexs);
        vm.expectRevert(abi.encodeWithSignature("AmountError(uint256)", 1));
        refund(issuer, 1, issuer, 1 ether);
        assertEq(address(issuer).balance, 800 ether);
        withdraw(worker, 1, worker);
        assertEq(address(worker).balance, 190 ether);
    }

    function testfailzero() public {
        vm.deal(owner, 0 ether); // init eth balance
        createOrder(issuer, zero, 100 ether);
        amounts = [100 ether]; //100
        periods = [172800]; // two day
        permitStage(issuer, worker, 1, amounts, periods, "Due", ""); // stage division
        payOrder(issuer, 100 ether, zero);
        vm.warp(0); //init time
        startOrder(issuer); // start order
        vm.warp(86400);

        stageIndexs = [0];
        vm.expectRevert(abi.encodeWithSignature("PermissionsError()"));
        confirmDelivery(zero, 1, stageIndexs);
    }

    //Due pay, issuer pass first stge and confirm second stge or third stge
    function testFailIssuerSkip1AndConfirm2() public {
        createOrder(issuer, address(0), 100 ether); // create order
        amounts = [20 ether, 40 ether, 60 ether];
        periods = [86400, 172800, 86400]; // one day
        permitStage(issuer, worker, 1, amounts, periods, "Due", ""); // stage division
        modifyOrder(issuer, 1, zero, 120 ether);
        payOrder(issuer, 120 ether, zero); // pay
        assertEq(address(issuer).balance, 880 ether);
        vm.warp(0); //init time
        startOrder(issuer); // start order
        vm.warp(8640); //  time passed 8640s
        stageIndexs = [1];
        confirmDelivery(issuer, 1, stageIndexs);
    }

    // Confirm pay, issuer pass first stge and confirm second stge or third stge
    function testFailConfirmIssuerSkip1AndConfirm2() public {
        createOrder(issuer, address(0), 100 ether); // create order
        amounts = [20 ether, 40 ether, 60 ether];
        periods = [86400, 172800, 86400]; // one day
        permitStage(issuer, worker, 1, amounts, periods, "Confirm", ""); // stage division
        modifyOrder(issuer, 1, zero, 120 ether);
        payOrder(issuer, 120 ether, zero); // pay
        assertEq(address(issuer).balance, 880 ether);
        vm.warp(0); //init time
        startOrder(issuer); // start order
        vm.warp(8640); //  time passed 8640s
        stageIndexs = [1];
        confirmDelivery(issuer, 1, stageIndexs);
    }

    // Confirm pay, time pass order time, to confirmDelivery
    function testConfirmOvertimeConfirmDelivery() public {
        createOrder(issuer, address(0), 100 ether); // create order
        amounts = [20 ether, 40 ether, 60 ether];
        periods = [86400, 172800, 86400]; // one day
        permitStage(issuer, worker, 1, amounts, periods, "Confirm", ""); // stage division
        modifyOrder(issuer, 1, zero, 120 ether);
        payOrder(issuer, 120 ether, zero); // pay
        assertEq(address(issuer).balance, 880 ether);
        vm.warp(0); //init time
        startOrder(issuer); // start order
        vm.warp(86400 * 100); //  time passed 8640s
        stageIndexs = [0];
        confirmDelivery(issuer, 1, stageIndexs);
    }

    // Due pay, time pass order time, to confirmDelivery
    function testDueOvertimeConfirmDelivery() public {
        createOrder(issuer, address(0), 100 ether); // create order
        amounts = [20 ether, 40 ether, 60 ether];
        periods = [86400, 172800, 86400]; // one day
        permitStage(issuer, worker, 1, amounts, periods, "Due", ""); // stage division
        modifyOrder(issuer, 1, zero, 120 ether);
        payOrder(issuer, 120 ether, zero); // pay
        assertEq(address(issuer).balance, 880 ether);
        vm.warp(0); //init time
        startOrder(issuer); // start order
        vm.warp(86400 * 100); //  time passed 8640s
        stageIndexs = [0];
        confirmDelivery(issuer, 1, stageIndexs);
    }
}
