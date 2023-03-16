// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "contracts/DeStage.sol";
import {DeOrderTest} from "./DeOrder.t.sol";

contract Common is DeOrderTest {
    // testUpdateAttachment
    function testUpdateAttachment() public {
        createOrder(issuer, address(0), 100); // create order
        permitStage(worker, issuer, 1, amounts, periods, "Due", ""); // stage division
        payOrder(issuer, 100, zero); // pay
        startOrder(issuer); // start order
        updateAttachment(
            worker,
            1,
            "Qmbjig3cZbUUufWqCEFzyCppqdnmQj3RoDjJWomnqYGy1f",
            ""
        );
    }

    // testUpdateAttachment fail
    function testCannotUpdateAttachment() public {
        // worng order id 
        updateAttachment(
            worker,
            1,
            "Qmbjig3cZbUUufWqCEFzyCppqdnmQj3RoDjJWomnqYGy1f",
            enFunc("PermissionsError()")
        );

        createOrder(issuer, address(0), 100); // create order
        permitStage(worker, issuer, 1, amounts, periods, "Due", ""); // stage division
        payOrder(issuer, 100, zero); // pay
        startOrder(issuer); // start order
        updateAttachment(
            other,
            1,
            "Qmbjig3cZbUUufWqCEFzyCppqdnmQj3RoDjJWomnqYGy1f",
            enFunc("PermissionsError()")
        );
    }

    // testsetSupportToken setSupportToken
    function testsetSupportToken() public {
        assertEq(deOrder.supportTokens(address(token0)), false);
        setSupportToken(owner, address(token0), true); // setSupportToken
        assertEq(deOrder.supportTokens(address(token0)), true);
    }

    // testCannotsetSupportToken setSupportToken fail
    function testCannotsetSupportToken() public {
        vm.startPrank(issuer);
        vm.expectRevert("Ownable: caller is not the owner");
        deOrder.setSupportToken(address(token0), true); // setSupportToken
        vm.stopPrank();
    }

    function testSetSBT() public {
        // not owner
        vm.startPrank(other);
        vm.expectRevert("Ownable: caller is not the owner");
        deOrder.setSBT(address(token0), address(permit2));
        vm.stopPrank();
        // owner
        vm.startPrank(owner);
        deOrder.setSBT(address(token0), address(permit2));
        assertEq(deOrder.builderSBT(), address(token0));
        assertEq(deOrder.issuerSBT(), address(permit2));
        vm.stopPrank();
    }

    function testSetFeeTo() public {
        // not owner
        vm.startPrank(other);
        vm.expectRevert("Ownable: caller is not the owner");
        deOrder.setFeeTo(100, address(issuer)); // %100
        vm.stopPrank();
        // owner
        vm.startPrank(owner);
        deOrder.setFeeTo(100, address(issuer)); // %100
        assertEq(deOrder.fee(), 100);
        assertEq(deOrder.feeTo(), address(issuer));
        vm.stopPrank();
    }

    function testTransferOwnership()public{
        vm.expectRevert("Ownable: caller is not the owner");
        deOrder.transferOwnership(issuer);
        vm.startPrank(owner);
        deOrder.transferOwnership(issuer);
        vm.stopPrank();
        assertEq(deOrder.owner(),issuer);
    }
}
