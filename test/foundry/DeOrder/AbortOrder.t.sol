// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/console2.sol";
import {DeOrderTest} from "./DeOrder.t.sol";
import "contracts/DeStage.sol";
contract AbortOrder is DeOrderTest {
    // testCannotAbortOrder
    // @Summary abort order fail
    function testCannotAbortOrder() public {
        createOrder(issuer, address(0), 100); // create order
        /* status not Ongoing to abort
         * @Expect abort fail
         */
        vm.expectRevert(abi.encodeWithSignature("ProgressError()"));
        abortOrder(issuer, 1); // abort order
        permitStage(issuer, worker, 1, amounts, periods, "Due", ""); // stage division
        payOrder(issuer, 100 ether, zero); // pay
        startOrder(issuer); // start order
        /* other to abort order
         * @Expect abort fail
         */
        vm.expectRevert(abi.encodeWithSignature("PermissionsError()"));
        abortOrder(other, 1);
    }

    //  testCannotAbortOrder
    //  @Summary abort order fail
    function testAbortOrder() public {
        createOrder(issuer, address(0), 100); // create order
        permitStage(issuer, worker, 1, amounts, periods, "Due", ""); // stage division
        payOrder(issuer, 100 ether, zero); // pay
        startOrder(issuer); // start order
        // abort order
        abortOrder(worker, 1);
        /* abort the finish order
         * @Expect abort fail
         */
        vm.expectRevert(abi.encodeWithSignature("ProgressError()"));
        abortOrder(worker, 1);
        vm.expectRevert(abi.encodeWithSignature("ProgressError()"));
        abortOrder(issuer, 1);
        vm.expectRevert(abi.encodeWithSignature("ProgressError()"));
        abortOrder(other, 1);
    }

    /* Due pay, abort timeout order
     * @Expect abort fail
     */
    function testDueLongtime() public {
        createOrder(issuer, address(0), 100); // create order
        permitStage(issuer, worker, 1, amounts, periods, "Due", ""); // stage division
        payOrder(issuer, 100 ether, zero); // pay
        startOrder(issuer); // start order
        vm.warp(17280 * 100); // add 17280s
        vm.expectRevert(abi.encodeWithSignature("StatusError()"));
        abortOrder(issuer, 1);
    }

    /* Confirm pay, timeout order confirmDelivery the first and abort order
     * @Expect abort success
     */
    function testConfirmLongtime() public {
        createOrder(issuer, address(0), 100); // create order
        permitStage(issuer, worker, 1, amounts, periods, "Confirm", ""); // stage division
        payOrder(issuer, 100 ether, zero); // pay
        startOrder(issuer); // start order
        vm.warp(17280 * 100); //add 17280s
        stageIndexs = [0];
        confirmDelivery(issuer, 1, stageIndexs);
        abortOrder(issuer, 1);
    }

    /* Due pay, 100 , time 17280*10s（two day）, one stage division, issuer in order half time abort order
     * @Expect abort success
     * @Assert refund amount same
     */
    function testCannotDueIusserAbortOrder() public {
        createOrder(issuer, address(0), 100 ether); // create order
        amounts = [100 ether]; //100
        periods = [172800]; // two day
        permitStage(issuer, worker, 1, amounts, periods, "Due", ""); // stage division
        payOrder(issuer, 100 ether, zero); // pay
        assertEq(address(issuer).balance, 900 ether); //issuer amount
        vm.warp(0); //init time
        startOrder(issuer); // start order
        vm.warp(17280 * 5); //increase 17280s
        abortOrder(issuer, 1); //issuerabort order
        assertEq(address(issuer).balance, 950 ether); //order finish issuer amount
        assertEq(address(worker).balance, 47.5 ether); //order finish worker amount
    }

    /* Due pay,100,time 17280*10s（two day), one stage division, worker in order half time abort order
     * @Expect abort success
     * @Assert refund amount same
     */
    function testCannotDueWorkerAbortOrder() public {
        createOrder(issuer, address(0), 100 ether); // create order
        amounts = [100 ether];
        periods = [172800]; // two day
        permitStage(issuer, worker, 1, amounts, periods, "Due", ""); // stage division
        payOrder(issuer, 100 ether, zero); // pay
        assertEq(address(issuer).balance, 900 ether);
        vm.warp(0); //init time
        startOrder(issuer); // start order
        vm.warp(17280 * 5); //increase one day
        abortOrder(worker, 1);
        assertEq(address(issuer).balance, 1000 ether);
        assertEq(address(worker).balance, 0 ether);
    }

    /* Confirm pay, 100, time 17280*10s（two day）, one stage division, worker in order half time abort order
     * @Expect abort success
     * @Assert refund amount same
     */
    function testCannotConfirmIusserAbortOrder() public {
        createOrder(issuer, address(0), 100 ether); // create order
        amounts = [100 ether];
        periods = [172800]; // two day
        permitStage(issuer, worker, 1, amounts, periods, "Confirm", ""); // stage division
        payOrder(issuer, 100 ether, zero); // pay
        assertEq(address(issuer).balance, 900 ether);
        vm.warp(0); //init time
        startOrder(issuer); // start order
        vm.warp(17280 * 5); //increase one day
        abortOrder(issuer, 1);
        assertEq(address(issuer).balance, 1000 ether);
        assertEq(address(worker).balance, 0 ether);
    }

    /* Confirm pay, overtime,abort order
     * @Expect abort success
     * @Assert refund amount same
     */
    function testCannotConfirmWorkerAbortOrder() public {
        createOrder(issuer, address(0), 100 ether); // create order
        amounts = [100 ether];
        periods = [172800]; // two day
        permitStage(issuer, worker, 1, amounts, periods, "Confirm", ""); // stage division
        payOrder(issuer, 100 ether, zero); // pay
        assertEq(address(issuer).balance, 900 ether);
        vm.warp(0); //init time
        startOrder(issuer); // start order
        vm.warp(17280 * 20); //increase 4 day
        abortOrder(worker, 1);
        assertEq(address(issuer).balance, 1000 ether);
        assertEq(address(worker).balance, 0 ether);
    }

    /* Due pay, issuer prolongStage, worker abort order
     * @Expect abort success
     * @Assert refund amount same
     */
    function testprolongStageDueIssuerAbortOrder() public {
        // vm.deal(owner, 0 ether);
        createOrder(issuer, address(0), 100 ether); // create order
        amounts = [100 ether];
        periods = [86400]; // one day
        permitStage(issuer, worker, 1, amounts, periods, "Due", ""); // stage division
        payOrder(issuer, 100 ether, zero); // pay
        assertEq(address(issuer).balance, 900 ether);
        vm.warp(0); //init time
        startOrder(issuer); // start order
        prolongStage(issuer, worker, 1, 0, 86400, ""); //prolong one day

        vm.warp(86400); // Time gone 1/5 day
        abortOrder(issuer, 1);
        assertEq(address(issuer).balance, 950 ether); //order finish issuer amount
        assertEq(address(worker).balance, 47.5 ether); //order finish worker amount
    }

    /* Due pay, worker prolongStage, worker abort order
     * @Expect abort success
     * @Assert refund amount same
     */
    function testprolongStageDueWorkerAbortOrder() public {
        createOrder(issuer, address(0), 100 ether); // create order
        amounts = [100 ether];
        periods = [86400]; // one day
        permitStage(issuer, worker, 1, amounts, periods, "Due", ""); // stage division
        payOrder(issuer, 100 ether, zero); // pay
        assertEq(address(issuer).balance, 900 ether);
        vm.warp(0); //init time
        startOrder(issuer); // start order
        prolongStage(worker, issuer, 1, 0, 86400, ""); //prolong one day
        vm.warp(86400); // Time gone 1/5 day
        abortOrder(worker, 1);
        assertEq(address(issuer).balance, 1000 ether); //order finish issuer amount
        assertEq(address(worker).balance, 0 ether); //order finish worker amount
    }

    /* Confirm pay, issuer prolongStage, worker abort order
     * @Expect abort success
     * @Assert refund amount same
     */
    function testprolongStageConfirmWorkerAbortOrder() public {
        createOrder(issuer, address(0), 100 ether); // create order
        amounts = [100 ether];
        periods = [86400]; // one day
        permitStage(issuer, worker, 1, amounts, periods, "Confirm", ""); // stage division
        payOrder(issuer, 100 ether, zero); // pay
        assertEq(address(issuer).balance, 900 ether);
        vm.warp(0); //init time
        startOrder(issuer); // start order
        prolongStage(worker, issuer, 1, 0, 86400, ""); //prolong one day
        vm.warp(86400); //Time gone 1/5 day
        abortOrder(worker, 1);
        assertEq(address(issuer).balance, 1000 ether); //order finish issuer amount
        assertEq(address(worker).balance, 0 ether); //order finish worker amount
    }

    /* Confirm pay, issuer prolongStage, issuer abort order
     * @Expect abort success
     * @Assert refund amount same
     */
    function testprolongStageConfirmIssuerAbortOrder() public {
        createOrder(issuer, address(0), 100 ether); // create order
        amounts = [100 ether];
        periods = [86400]; // one day
        permitStage(issuer, worker, 1, amounts, periods, "Confirm", ""); // stage division
        payOrder(issuer, 100 ether, zero); // pay
        assertEq(address(issuer).balance, 900 ether);
        vm.warp(0); //init time
        startOrder(issuer); // start order
        prolongStage(issuer, worker, 1, 0, 86400, ""); //prolong one day
        vm.warp(86400); // time gone 1/5 day
        abortOrder(issuer, 1);
        assertEq(address(issuer).balance, 1000 ether); //order finish issuer amount
        assertEq(address(worker).balance, 0 ether); //order finish worker amount
    }

    /* Due pay, done two stage, issuer abort order, time in third stage
     * @Expect abort success
     * @Assert refund amount same
     */
    function testMoreDueIusserAbortOrder() public {
        createOrder(issuer, address(0), 100 ether); // create order
        amounts = [20 ether, 40 ether, 60 ether];
        periods = [86400, 172800, 259200]; // one day
        permitStage(issuer, worker, 1, amounts, periods, "Due", ""); // stage division
        modifyOrder(issuer, 1, zero, 120 ether); //
        payOrder(issuer, 120 ether, zero); // pay
        assertEq(address(issuer).balance, 880 ether);
        vm.warp(0); //init time
        startOrder(issuer); // start order
        vm.warp(388800); // time gone 3 day
        abortOrder(issuer, 1);
        assertEq(address(issuer).balance, 910 ether); //order finish issuer amount
        assertEq(address(worker).balance, 85.5 ether); //order finish worker amount
    }

    /* Due pay, done two stage, worker abort order, time in third stage
     * @Expect abort success
     * @Assert refund amount same
     */
    function testMoreDueWorkerAbortOrder() public {
        createOrder(issuer, address(0), 100 ether); // create order
        amounts = [20 ether, 40 ether, 60 ether];
        periods = [86400, 172800, 259200]; // one day
        permitStage(issuer, worker, 1, amounts, periods, "Due", ""); // stage division
        modifyOrder(issuer, 1, zero, 120 ether);
        payOrder(issuer, 120 ether, zero); // pay
        assertEq(address(issuer).balance, 880 ether);
        vm.warp(0); //init time
        startOrder(issuer); // start order
        vm.warp(388800); // time gone 3 day
        abortOrder(worker, 1);
        assertEq(address(issuer).balance, 940 ether); //order finish issuer amount
        assertEq(address(worker).balance, 57 ether); //order finish worker amount
    }

    // Confirm pay,done two stage, issuer abort order, time in third stage
    function testMoreConfirmIusserAbortOrder() public {
        createOrder(issuer, address(0), 100 ether); // create order
        amounts = [20 ether, 40 ether, 60 ether];
        periods = [86400, 172800, 259200]; // one day
        permitStage(issuer, worker, 1, amounts, periods, "Confirm", ""); // stage division
        modifyOrder(issuer, 1, zero, 120 ether); 
        payOrder(issuer, 120 ether, zero); // pay
        assertEq(address(issuer).balance, 880 ether);
        // vm.warp(0); //init time
        startOrder(issuer); // start order
        stageIndexs = [0, 1];
        confirmDelivery(issuer, 1, stageIndexs);
        // vm.warp(388800); // time gone 3 day
        abortOrder(issuer, 1);
        assertEq(address(issuer).balance, 940 ether); //order finish issuer amount
        assertEq(address(worker).balance, 57 ether); //order finish worker amount
    }

    // Confirm pay,done two stage, worker abort order, time in third stage
    function testMoreConfirmWorkerAbortOrder() public {
        createOrder(issuer, address(0), 100 ether); // create order
        amounts = [20 ether, 40 ether, 60 ether];
        periods = [86400, 172800, 259200]; // one day
        permitStage(issuer, worker, 1, amounts, periods, "Confirm", ""); // stage division
        modifyOrder(issuer, 1, zero, 120 ether); 
        payOrder(issuer, 120 ether, zero); // pay
        assertEq(address(issuer).balance, 880 ether);
        vm.warp(0); //init time
        startOrder(issuer); // start order
        stageIndexs = [0, 1];
        confirmDelivery(issuer, 1, stageIndexs);
        vm.warp(388800); // time gone 3 day
        abortOrder(worker, 1);
        assertEq(address(issuer).balance, 940 ether); //order finish issuer amount
        assertEq(address(worker).balance, 57 ether); //order finish worker amount
    }

    //1 stage, Due issuer increase stage, issuer abort order
    function testMoreDueIssuerAppendStageIssuerAbortOrder() public {
        createOrder(issuer, address(0), 100 ether); // create order
        amounts = [20 ether, 40 ether];
        periods = [86400, 172800]; // one day
        permitStage(issuer, worker, 1, amounts, periods, "Due", ""); // stage division
        modifyOrder(issuer, 1, zero, 60 ether); 
        payOrder(issuer, 60 ether, zero); // pay
        assertEq(address(issuer).balance, 940 ether);
        vm.warp(0); //init time
        startOrder(issuer); // start order
        payOrder(issuer, 60 ether, zero);
        appendStage(issuer, worker, 1, 60 ether, 259200, "");
        vm.warp(388800); //time gone 3 day
        abortOrder(issuer, 1);
        assertEq(address(issuer).balance, 910 ether); //order finish issuer amount
        assertEq(address(worker).balance, 85.5 ether); //order finish worker amount
    }

    // 1 stage, Due issuer increase stage, worker abort order
    function testMorDueIssuererAppendStageWorkerAbortOrder() public {
        createOrder(issuer, address(0), 100 ether); // create order
        amounts = [20 ether, 40 ether];
        periods = [86400, 172800]; // one day
        permitStage(issuer, worker, 1, amounts, periods, "Due", ""); // stage division
        modifyOrder(issuer, 1, zero, 60 ether); 
        payOrder(issuer, 60 ether, zero); // pay
        assertEq(address(issuer).balance, 940 ether);
        vm.warp(0); //init time
        startOrder(issuer); // start order
        payOrder(issuer, 60 ether, zero);
        appendStage(issuer, worker, 1, 60 ether, 259200, "");
        vm.warp(388800); //time gone 3 day
        abortOrder(worker, 1);
        assertEq(address(issuer).balance, 940 ether); //order finish issuer amount
        assertEq(address(worker).balance, 57 ether); //order finish worker amount
    }

    // 1 stage, Due worker increase stage, issuer abort order
    function testMoreDueWorkerAppendStageIssuerAbortOrder() public {
        // vm.deal(owner, 0 ether);
        createOrder(issuer, address(0), 100 ether); // create order
        amounts = [20 ether, 40 ether];
        periods = [86400, 172800]; // one day
        permitStage(issuer, worker, 1, amounts, periods, "Due", ""); // stage division
        modifyOrder(issuer, 1, zero, 60 ether); 
        payOrder(issuer, 60 ether, zero); // pay
        assertEq(address(issuer).balance, 940 ether);
        vm.warp(0); //init time
        startOrder(issuer); // start order
        payOrder(issuer, 60 ether, zero);
        appendStage(worker, issuer, 1, 60 ether, 259200, "");
        vm.warp(388800); //time gone 3 day
        abortOrder(issuer, 1);
        assertEq(address(issuer).balance, 910 ether); //order finish issuer amount
        assertEq(address(worker).balance, 85.5 ether); //order finish worker amount
        // console2.log(address(issuer).balance);
        // console2.log(address(worker).balance);
        // console2.log(address(_weth).balance);
        // console2.log(address(issuer).balance+address(worker).balance+address(_weth).balance+address(owner).balance);
    }

    // 1 stage, Due issuer increase stage, issuer abort order
    function testMoreConfirmIssuerAppendStageIssuerAbortOrder() public {
        createOrder(issuer, address(0), 100 ether); // create order
        amounts = [20 ether, 40 ether];
        periods = [86400, 172800]; // one day
        permitStage(issuer, worker, 1, amounts, periods, "Confirm", ""); // stage division
        modifyOrder(issuer, 1, zero, 60 ether); 
        payOrder(issuer, 60 ether, zero); // pay
        assertEq(address(issuer).balance, 940 ether);
        vm.warp(0); //init time
        startOrder(issuer); // start order
        payOrder(issuer, 60 ether, zero);
        appendStage(issuer, worker, 1, 60 ether, 259200, "");
        vm.warp(388800); //time gone 3 day
        stageIndexs = [0];
        confirmDelivery(issuer, 1, stageIndexs);
        abortOrder(issuer, 1);
        assertEq(address(issuer).balance, 980 ether); //order finish issuer amount
        assertEq(address(worker).balance, 19 ether); //order finish worker amount
    }

    // 1 stage, Due issuer increase stage, worker abort order
    function testMoreConfirmdIssuererAppendStageWorkerAbortOrder() public {
        createOrder(issuer, address(0), 100 ether); // create order
        amounts = [20 ether, 40 ether];
        periods = [86400, 172800]; // one day
        permitStage(issuer, worker, 1, amounts, periods, "Confirm", ""); // stage division
        modifyOrder(issuer, 1, zero, 60 ether); 
        payOrder(issuer, 60 ether, zero); // pay
        assertEq(address(issuer).balance, 940 ether);
        vm.warp(0); //init time
        startOrder(issuer); // start order
        payOrder(issuer, 60 ether, zero);
        appendStage(issuer, worker, 1, 60 ether, 259200, "");
        vm.warp(388800); //time gone 3 day
        stageIndexs = [0];
        confirmDelivery(issuer, 1, stageIndexs);
        abortOrder(worker, 1);
        assertEq(address(issuer).balance, 980 ether); //order finish issuer amount
        assertEq(address(worker).balance, 19 ether); //order finish worker amount
    }

    // 1 stage, Due worker increase stage, issuer abort order
    function testMoreConfirmWorkerAppendStageIssuerAbortOrder() public {
        // vm.deal(owner, 0 ether);
        createOrder(issuer, address(0), 100 ether); // create order
        amounts = [20 ether, 40 ether];
        periods = [86400, 172800]; // one day
        permitStage(issuer, worker, 1, amounts, periods, "Confirm", ""); // stage division
        modifyOrder(issuer, 1, zero, 60 ether); 
        payOrder(issuer, 60 ether, zero); // pay
        assertEq(address(issuer).balance, 940 ether);
        vm.warp(0); //init time
        startOrder(issuer); // start order
        payOrder(issuer, 60 ether, zero);
        appendStage(worker, issuer, 1, 60 ether, 259200, "");
        vm.warp(388800); //time gone 3 day
        stageIndexs = [0];
        confirmDelivery(issuer, 1, stageIndexs);
        abortOrder(issuer, 1);
        assertEq(address(issuer).balance, 980 ether); //order finish issuer amount
        assertEq(address(worker).balance, 19 ether); //order finish worker amount
        // console2.log(address(issuer).balance);
        // console2.log(address(worker).balance);
        // console2.log(address(_weth).balance);
        // console2.log(address(issuer).balance+address(worker).balance+address(_weth).balance+address(owner).balance);
    }

    // Confirm pay, over time, issuer abort order
    function testOvertimeConfirmIssuerAbortOrder() public {
        createOrder(issuer, address(0), 100 ether); // create order
        amounts = [20 ether, 40 ether, 60 ether];
        periods = [86400, 172800, 259200]; // one day
        permitStage(issuer, worker, 1, amounts, periods, "Confirm", ""); // stage division
        modifyOrder(issuer, 1, zero, 120 ether); 
        payOrder(issuer, 120 ether, zero); // pay
        assertEq(address(issuer).balance, 880 ether);
        vm.warp(0); //init time
        startOrder(issuer); // start order
        stageIndexs = [0, 1];
        confirmDelivery(issuer, 1, stageIndexs);
        vm.warp(3898010); //time gone 3 day
        abortOrder(issuer, 1);
        assertEq(address(issuer).balance, 940 ether); //order finish issuer amount
        assertEq(address(worker).balance, 57 ether); //order finish worker amount
    }

    // Confirm pay, over time, worker abort order
    function testOvertimeConfirmWorkerAbortOrder() public {
        createOrder(issuer, address(0), 100 ether); // create order
        amounts = [20 ether, 40 ether, 60 ether];
        periods = [86400, 172800, 259200]; // one day
        permitStage(issuer, worker, 1, amounts, periods, "Confirm", ""); // stage division
        modifyOrder(issuer, 1, zero, 120 ether); 
        payOrder(issuer, 120 ether, zero); // pay
        assertEq(address(issuer).balance, 880 ether);
        vm.warp(0); //init time
        startOrder(issuer); // start order
        stageIndexs = [0, 1];
        confirmDelivery(issuer, 1, stageIndexs);
        vm.warp(3898010); //time gone 3 day
        abortOrder(worker, 1);
        assertEq(address(issuer).balance, 940 ether); //order finish issuer amount
        assertEq(address(worker).balance, 57 ether); //order finish worker amount
    }

    // Due pay, over time, issuer abort order
    function testFailOvertimeDueIssuerAbortOrder() public {
        createOrder(issuer, address(0), 100 ether); // create order
        amounts = [20 ether, 40 ether, 60 ether];
        periods = [86400, 172800, 259200]; // one day
        permitStage(issuer, worker, 1, amounts, periods, "Due", ""); // stage division
        modifyOrder(issuer, 1, zero, 120 ether); 
        payOrder(issuer, 120 ether, zero); // pay
        assertEq(address(issuer).balance, 880 ether);
        vm.warp(0); //init time
        startOrder(issuer); // start order
        stageIndexs = [0, 1];
        confirmDelivery(issuer, 1, stageIndexs);
        vm.warp(3898010); //time gone 3 day
        abortOrder(issuer, 1);
        // assertEq(address(issuer).balance, 1000 ether); //order finish issuer amount
        // assertEq(address(worker).balance, 0 ether); //order finish worker amount
    }

    function testFailOvertimeDueWorkerAbortOrder() public {
        createOrder(issuer, address(0), 100 ether); // create order
        amounts = [20 ether, 40 ether, 60 ether];
        periods = [86400, 172800, 259200]; // one day
        permitStage(issuer, worker, 1, amounts, periods, "Due", ""); // stage division
        modifyOrder(issuer, 1, zero, 120 ether); 
        payOrder(issuer, 120 ether, zero); // pay
        assertEq(address(issuer).balance, 880 ether);
        vm.warp(0); //init time
        startOrder(issuer); // start order
        stageIndexs = [0, 1];
        confirmDelivery(worker, 1, stageIndexs);
        vm.warp(3898010); //time gone 3 day
        abortOrder(issuer, 1);
        // assertEq(address(issuer).balance, 1000 ether); //order finish issuer amount
        // assertEq(address(worker).balance, 0 ether); //order finish worker amount
    }

    function testAbortOrderWWWR() public {
        createOrder(issuer, address(0), 100 ether); // create order
        amounts = [20 ether, 40 ether, 60 ether];
        periods = [86400, 172800, 259200]; // one day
        permitStage(issuer, worker, 1, amounts, periods, "Confirm", ""); // stage division
        modifyOrder(issuer, 1, zero, 120 ether); 
        payOrder(issuer, 120 ether, zero); // pay
        assertEq(address(issuer).balance, 880 ether);
        vm.warp(0); //init time
        startOrder(issuer); // start order
        // stageIndexs = [0, 1];
        // confirmDelivery(worker, 1, stageIndexs);
        // vm.warp(3898010); //time gone 3 day
        abortOrder(issuer, 1);
        DeStage.Stage[] memory stages  = deOrder.getStages(1);
        // console2.log(stages[0]);
        // assertEq(address(issuer).balance, 1000 ether); //order finish issuer amount
        // assertEq(address(worker).balance, 0 ether); //order finish worker amount
    }
}
