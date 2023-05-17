// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {DeOrderTest} from "./DeOrder.t.sol";
import "forge-std/console2.sol";
contract Withdraw is DeOrderTest {
    // issuer check worker withdraw
    // @Summary SubmitDelivery and issuer confirm and worker withdraw
    //due
    function testDueWithdraw() public {
        vm.deal(owner, 0 ether); // init eth balance
        createOrder(issuer, address(0), 100 ether); // create order

        vm.expectRevert(abi.encodeWithSignature("PermissionsError()"));
        withdraw(issuer,1, issuer);
        vm.expectRevert(abi.encodeWithSignature("ProgressError()"));
        withdraw(worker,1, worker);
        vm.expectRevert(abi.encodeWithSignature("PermissionsError()"));
        withdraw(other, 1, other);

        amounts = [100 ether]; // 100
        periods = [172800]; // two day
        permitStage(issuer, worker, 1, amounts, periods, "Due", ""); // stage division

        vm.expectRevert(abi.encodeWithSignature("PermissionsError()"));
        withdraw(issuer,1, issuer);
        vm.expectRevert(abi.encodeWithSignature("ProgressError()"));
        withdraw(worker,1, worker);
        vm.expectRevert(abi.encodeWithSignature("PermissionsError()"));
        withdraw(other, 1, other);

        payOrder(issuer, 200 ether, zero); // pay

        vm.expectRevert(abi.encodeWithSignature("PermissionsError()"));
        withdraw(issuer,1, issuer);
        vm.expectRevert(abi.encodeWithSignature("ProgressError()"));
        withdraw(worker,1, worker);
        vm.expectRevert(abi.encodeWithSignature("PermissionsError()"));
        withdraw(other, 1, other);

        //order start
        vm.warp(0); // init time
        startOrder(issuer); // start order
        vm.warp(10000);

        //order ongoing
        vm.expectRevert(abi.encodeWithSignature("PermissionsError()"));
        withdraw(issuer,1, issuer);
        withdraw(worker,1, worker);
        assertEq(address(worker).balance, 0 ether);
        vm.expectRevert(abi.encodeWithSignature("PermissionsError()"));
        withdraw(other, 1, other);

        // order prolong
        prolongStage(issuer, worker, 1, 0, 1000, "");
        vm.expectRevert(abi.encodeWithSignature("PermissionsError()"));
        withdraw(issuer,1, issuer);
        withdraw(worker,1, worker);
        assertEq(address(worker).balance, 0 ether);
        vm.expectRevert(abi.encodeWithSignature("PermissionsError()"));
        withdraw(other, 1, other);

        // increase stage
        appendStage(issuer, worker, 1, 100 ether, 4000, "");
        payOrder(issuer, 100 ether, zero); // pay
        vm.warp(100000);
        vm.expectRevert(abi.encodeWithSignature("PermissionsError()"));
        withdraw(issuer,1, issuer);
        withdraw(worker,1, worker);
        assertEq(address(worker).balance, 0 ether);
        vm.expectRevert(abi.encodeWithSignature("PermissionsError()"));
        withdraw(other, 1, other);

        vm.expectRevert(abi.encodeWithSignature("PermissionsError()"));
        withdraw(issuer,1, issuer);
        withdraw(worker,1, worker);
        assertEq(address(worker).balance, 0 ether);
        vm.expectRevert(abi.encodeWithSignature("PermissionsError()"));
        withdraw(other, 1, other);

        // first stage done
        vm.warp(173800);
        vm.expectRevert(abi.encodeWithSignature("PermissionsError()"));
        withdraw(issuer,1, issuer);
        withdraw(worker,1, worker);
        assertEq(address(worker).balance, 95 ether);
        vm.expectRevert(abi.encodeWithSignature("PermissionsError()"));
        withdraw(other, 1, other);

        // order done
        vm.warp(1728000);
        vm.expectRevert(abi.encodeWithSignature("PermissionsError()"));
        withdraw(issuer,1, issuer);
        withdraw(worker,1, worker);
        
        assertEq(address(worker).balance, 190 ether);
        vm.expectRevert(abi.encodeWithSignature("PermissionsError()"));
        withdraw(other, 1, other);
        vm.expectRevert(abi.encodeWithSignature("ProgressError()"));
        withdraw(worker,1, worker);
        assertEq(address(worker).balance, 190 ether);
 

        console2.log(address(issuer).balance);
        console2.log(address(worker).balance);
        console2.log(address(_weth).balance);
        console2.log(address(owner).balance);
    }
    
    //Confirm
    function testConfirmWithdraw() public {
        vm.deal(owner, 0 ether); // init eth balance
        createOrder(issuer, address(0), 100 ether); // create order

        vm.expectRevert(abi.encodeWithSignature("PermissionsError()"));
        withdraw(issuer,1, issuer);
        vm.expectRevert(abi.encodeWithSignature("ProgressError()"));
        withdraw(worker,1, worker);
        vm.expectRevert(abi.encodeWithSignature("PermissionsError()"));
        withdraw(other, 1, other);

        amounts = [100 ether]; //100
        periods = [172800]; // two day
        permitStage(issuer, worker, 1, amounts, periods, "Confirm", ""); // stage division

        vm.expectRevert(abi.encodeWithSignature("PermissionsError()"));
        withdraw(issuer,1, issuer);
        vm.expectRevert(abi.encodeWithSignature("ProgressError()"));
        withdraw(worker,1, worker);
        vm.expectRevert(abi.encodeWithSignature("PermissionsError()"));
        withdraw(other, 1, other);

        payOrder(issuer, 200 ether, zero); // pay

        vm.expectRevert(abi.encodeWithSignature("PermissionsError()"));
        withdraw(issuer,1, issuer);
        vm.expectRevert(abi.encodeWithSignature("ProgressError()"));
        withdraw(worker,1, worker);
        vm.expectRevert(abi.encodeWithSignature("PermissionsError()"));
        withdraw(other, 1, other);

        // order start
        vm.warp(0); //init time
        startOrder(issuer); // start order
        vm.warp(10000);

        // order ongoing
        vm.expectRevert(abi.encodeWithSignature("PermissionsError()"));
        withdraw(issuer,1, issuer);
        withdraw(worker,1, worker);
        assertEq(address(worker).balance, 0 ether);
        vm.expectRevert(abi.encodeWithSignature("PermissionsError()"));
        withdraw(other, 1, other);

        // order prolong
        prolongStage(issuer, worker, 1, 0, 1000, "");
        vm.expectRevert(abi.encodeWithSignature("PermissionsError()"));
        withdraw(issuer,1, issuer);
        withdraw(worker,1, worker);
        assertEq(address(worker).balance, 0 ether);
        vm.expectRevert(abi.encodeWithSignature("PermissionsError()"));
        withdraw(other, 1, other);

        // increase stage
        appendStage(issuer, worker, 1, 100 ether, 4000, "");
        payOrder(issuer, 100 ether, zero); // pay
        vm.warp(100000);
        vm.expectRevert(abi.encodeWithSignature("PermissionsError()"));
        withdraw(issuer,1, issuer);
        withdraw(worker,1, worker);
        assertEq(address(worker).balance, 0 ether);
        vm.expectRevert(abi.encodeWithSignature("PermissionsError()"));
        withdraw(other, 1, other);

        vm.expectRevert(abi.encodeWithSignature("PermissionsError()"));
        withdraw(issuer,1, issuer);
        withdraw(worker,1, worker);
        assertEq(address(worker).balance, 0 ether);
        vm.expectRevert(abi.encodeWithSignature("PermissionsError()"));
        withdraw(other, 1, other);

        // first stage done
        vm.warp(173800);
        stageIndexs = [0];
        confirmDelivery(issuer, 1, stageIndexs);
        vm.expectRevert(abi.encodeWithSignature("PermissionsError()"));
        withdraw(issuer,1, issuer);
        withdraw(worker,1, worker);
        assertEq(address(worker).balance, 95 ether);
        vm.expectRevert(abi.encodeWithSignature("PermissionsError()"));
        withdraw(other, 1, other);

        // order done
        vm.warp(1728000);
        stageIndexs = [1];
        confirmDelivery(issuer, 1, stageIndexs);

        //  order done
        vm.expectRevert(abi.encodeWithSignature("PermissionsError()"));
        withdraw(issuer,1, issuer);
        withdraw(worker,1, worker);
        
        assertEq(address(worker).balance, 190 ether);
        vm.expectRevert(abi.encodeWithSignature("PermissionsError()"));
        withdraw(other, 1, other);
        vm.expectRevert(abi.encodeWithSignature("ProgressError()"));
        withdraw(worker,1, worker);
        assertEq(address(worker).balance, 190 ether);
    }


}
