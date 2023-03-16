// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/console2.sol";
import "contracts/DeStage.sol";
import "contracts/interface/IOrder.sol";
import {DeOrderTest} from "./DeOrder.t.sol";

contract SpecialTest is DeOrderTest {
    // Confirm Type not affected by time
    function testSpecialConfirmNotTime() public {
        setSupportToken(owner, address(token0), true);
        createOrder(issuer, address(token0), 100); // create order
        amounts = [50, 25, 25];
        periods = [1000, 1000, 1000];
        permitStage(worker, issuer, 1, amounts, periods, "Confirm", ""); // normal permitStage
        vm.warp(0); //init time
        payOrderWithPermit2(issuer, 1, 100, address(token0));
        // issuer 
        startOrder(issuer);
        (uint t1, ) = deOrder.ongoingStage(1);
        assertEq(t1, 0);
        vm.warp(1002); //init time
        (uint t2, ) = deOrder.ongoingStage(1);
        assertEq(t2, 0);

        stageIndexs = [0, 1];
        confirmDelivery(issuer, 1, stageIndexs);

        (uint t3, ) = deOrder.ongoingStage(1);
        assertEq(t3, 2);
        console2.log(t3);
    }

    // Due pay and confirmDelivery
    function testSpecialDueAndConfirm() public {
        uint balance = token0.balanceOf(worker);
        setSupportToken(owner, address(token0), true);
        createOrder(issuer, address(token0), 100); // create order
        amounts = [50, 25, 25];
        periods = [1000, 1000, 1000];
        permitStage(worker, issuer, 1, amounts, periods, "Due", ""); // normal permitStage
        vm.warp(0); //init time
        payOrderWithPermit2(issuer, 1, 100, address(token0));
        // issuer
        startOrder(issuer);
        (uint t1, ) = deOrder.ongoingStage(1);
        assertEq(t1, 0);
       
        (uint t2, ) = deOrder.ongoingStage(1);
        assertEq(t2, 0);

        stageIndexs = [0, 1];
        confirmDelivery(issuer, 1, stageIndexs);

        (uint t3, ) = deOrder.ongoingStage(1);
        assertEq(t3, 2);

         vm.warp(3002);

        withdraw(worker,1, worker);

        assertEq(token0.balanceOf(worker), balance+95);
        // (uint t4, ) = deOrder.ongoingStage(1);
        // assertEq(t4, 2);
        // console2.log(t4);
    }
}
