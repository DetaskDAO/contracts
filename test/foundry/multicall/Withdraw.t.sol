// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "../DeOrder/DeOrder.t.sol";

contract WithdrawMulticallTest is DeOrderTest {
    function multicall(address who, bytes[] memory data) public {
        vm.startPrank(who);
        deOrder.multicall(data);
        vm.stopPrank();
    }

    // testMulticallPayOrderWithToken Multicall payToken
    function testFailMulticallWithdraw() public {
        createOrder(issuer, address(0), 100); // create order
        vm.deal(address(_weth), 1 ether); // init eth balance
        permitStage(worker, issuer, 1, amounts, periods, "Due", ""); // stage division
        payOrder(issuer, 100, zero); // pay
        startOrder(issuer); // start order
        stageIndexs = [0, 1];
        confirmDelivery(issuer, 1, stageIndexs);

        bytes[] memory data = new bytes[](2);
        data[0] = abi.encodeWithSelector(deOrder.withdraw.selector, 1, worker);
        data[1] = abi.encodeWithSelector(deOrder.withdraw.selector, 1, worker);

        vm.startPrank(worker);
        vm.expectRevert(abi.encodeWithSignature("ProgressError()"));
        deOrder.multicall(data);
        vm.stopPrank();
        assertEq(address(deOrder).balance, 95);
    }
}
