// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "../DeOrder/DeOrder.t.sol";

contract AbortOrderMulticallTest is DeOrderTest {
    function multicall(address who, bytes[] memory data) public {
        vm.startPrank(who);
        deOrder.multicall(data);
        vm.stopPrank();
    }

    //Due pay, 100, 17280*10s（two day）, one stage division order, issuer in half time abort order
    function testFailMulticallCannotDueIusserAbortOrder() public {
        createOrder(issuer, address(0), 100 ether); // create order
        amounts = [100 ether]; //100
        periods = [172800]; // two day
        permitStage(issuer, worker, 1, amounts, periods, "Confirm", ""); // stage division
        payOrder(issuer, 100 ether, zero); // pay
        assertEq(address(issuer).balance, 900 ether); // issuer amount
        vm.warp(0); //init time
        startOrder(issuer); // start order
        vm.warp(17280 * 5); //increase 17280s
        // abortOrder(issuer, 1);
        bytes[] memory data = new bytes[](2);
        data[0] = abi.encodeWithSelector(deOrder.abortOrder.selector, 1);
        data[1] = abi.encodeWithSelector(deOrder.abortOrder.selector, 1);
        vm.startPrank(issuer);
        deOrder.multicall(data);
        vm.stopPrank();
        assertEq(address(issuer).balance, 1000 ether);
        assertEq(address(worker).balance, 0 ether);
    }
}
