// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "contracts/DeStage.sol";
import "contracts/interface/IOrder.sol";
import "contracts/libs/ECDSA.sol";
import {DeOrderTest} from "./DeOrder.t.sol";

contract PermitStage is DeOrderTest {
    // testPermitStage
    // @Summary stage division
    function testPermitStage() public {
        createOrder(issuer, address(0), 100); // create order
        // issuersignature worker submit
        amounts = [100];
        periods = [1000];
        permitStage(issuer, worker, 1, amounts, periods, "Due", "");
        Order memory order = deOrder.getOrder(1);
        DeStage.Stage[] memory stages = deOrder.getStages(1);
        assertTrue(order.progress == OrderProgess.Staged);
        assertEq(stages[0].amount, 100);
        assertEq(stages[0].period, 1000);
        assertTrue(order.payType == PaymentType.Due); // pay mode
    }

    // testPermitStage
    // @Summary stage division
    function testPermitStage2() public {
        createOrder(issuer, address(0), 100); // create order
        amounts = [100];
        periods = [1000];
        // workersignature issuer submit
        permitStage(worker, issuer, 1, amounts, periods, "Confirm", "");
        Order memory order = deOrder.getOrder(1);
        DeStage.Stage[] memory stages = deOrder.getStages(1);
        assertTrue(order.progress == OrderProgess.Staged);
        assertEq(stages[0].amount, 100);
        assertEq(stages[0].period, 1000);
        assertTrue(order.payType == PaymentType.Confirm); // pay mode
    }

    // testCannotPermitStage
    // @Summary Permit stage division fail
    function testCannotPermitStage() public {
        createOrder(issuer, address(0), 100); // create order
        // issuer signature && issuer submit
        permitStage(
            issuer,
            issuer,
            1,
            amounts,
            periods,
            "Due",
            enFunc("PermissionsError()")
        );
        // workersignature && worker submit
        permitStage(
            worker,
            worker,
            1,
            amounts,
            periods,
            "Due",
            enFunc("PermissionsError()")
        );
        // workersignature && order submit
        permitStage(
            worker,
            other,
            1,
            amounts,
            periods,
            "Due",
            enFunc("PermissionsError()")
        );
        // orther signature && worker submit
        permitStage(
            other,
            worker,
            1,
            amounts,
            periods,
            "Due",
            enFunc("PermissionsError()")
        );
        // orther signature && orther submit
        permitStage(
            owner,
            other,
            1,
            amounts,
            periods,
            "Due",
            enFunc("PermissionsError()")
        );
        // deadline expired
        vm.warp(202);
        permitStage(
            worker,
            issuer,
            1,
            amounts,
            periods,
            "Due",
            enFunc("Expired()")
        );
        vm.warp(0);
        // order ongoing
        permitStage(worker, issuer, 1, amounts, periods, "Due", ""); // normal permitStage
        payOrder(issuer, 100, zero); // pay
        startOrder(issuer); // start order
        permitStage(
            worker,
            issuer,
            1,
            amounts,
            periods,
            "Due",
            enFunc("ProgressError()")
        );
    }

    // memory _amounts and memory _periods length not equal
    function testCannotPermitStageWithArrayErr() public {
        createOrder(issuer, address(0), 100); // create order
        amounts = [100];
        periods = [100, 900];

        permitStage(
            worker,
            issuer,
            1,
            amounts,
            periods,
            "Due",
            abi.encodeWithSignature("ParamError()")
        );
    }

    // nonce incorrect
    function testCannotPermitStageWithErrNonce() public {
        createOrder(issuer, address(0), 100); // create order
        uint256 _orderId = 1;
        amounts = [100];
        periods = [1000];
        // not exists nonce
        uint256 nonce = 13;
        uint256 deadline = 200;
        bytes32 structHash = keccak256(
            abi.encode(
                deOrder.PERMITSTAGE_TYPEHASH(),
                _orderId,
                keccak256(abi.encodePacked(amounts)),
                keccak256(abi.encodePacked(periods)),
                PaymentType.Confirm,
                nonce,
                deadline
            )
        );
        bytes32 digest = ECDSA.toTypedDataHash(
            deOrder.DOMAIN_SEPARATOR(),
            structHash
        );
        // signature
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = vm.sign(2, digest);
        vm.startPrank(issuer);
        vm.expectRevert(abi.encodeWithSignature("NonceError()"));
        deOrder.permitStage(
            _orderId,
            amounts,
            periods,
            PaymentType.Confirm,
            nonce,
            deadline,
            v,
            r,
            s
        );
        vm.stopPrank();
        // already used Nonce
        permitStage(worker, issuer, 1, amounts, periods, "Due", "");
        nonce = 0;
        structHash = keccak256(
            abi.encode(
                deOrder.PERMITSTAGE_TYPEHASH(),
                _orderId,
                keccak256(abi.encodePacked(amounts)),
                keccak256(abi.encodePacked(periods)),
                PaymentType.Confirm,
                nonce,
                deadline
            )
        );
        digest = ECDSA.toTypedDataHash(
            deOrder.DOMAIN_SEPARATOR(),
            structHash
        );
        // signature
        (v, r, s) = vm.sign(2, digest);
        vm.startPrank(issuer);
        vm.expectRevert(abi.encodeWithSignature("NonceError()"));
        deOrder.permitStage(
            _orderId,
            amounts,
            periods,
            PaymentType.Confirm,
            nonce,
            deadline,
            v,
            r,
            s
        );
        vm.stopPrank();
    }
}
