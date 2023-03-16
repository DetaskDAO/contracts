// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "contracts/interface/IOrder.sol";
import "contracts/libs/ECDSA.sol";
import {MockERC20} from "../mock/MockERC20.sol";
import {DeOrder} from "contracts/DeOrder.sol";
import {WETH} from "contracts/mock/WETH.sol";
import {AttackRefund} from "./AttackRefund.sol";
import {AttackWithdraw} from "./AttackWithdraw.sol";
import {AttackMulticallWithdraw} from "./AttackMulticallWithdraw.sol";
import {AttackTransfer} from "./AttackTransfer.t.sol";
import {AttackModifyOrder} from "./AttackModifyOrder.sol";
import {AttackAbortOrder} from "./AttackAbortOrder.sol";

contract AttackTest is Test {
    AttackRefund attackRefund;
    AttackWithdraw attackWithdraw;
    AttackTransfer attackTransfer;
    AttackMulticallWithdraw attackMulticallWithdraw;
    AttackModifyOrder attackModifyOrder;
    AttackAbortOrder attackAbortOrder;
    DeOrder public deOrder;
    WETH public weth;
    MockERC20 token0;
    address owner; // owner
    address issuer; // issuer
    address other; // other
    uint256[] amounts = [1 ether];
    uint256[] periods = [1000];

    function setUp() public {
        token0 = new MockERC20("Test0", "TEST0", 18);
        owner = msg.sender;
        issuer = vm.addr(1);
        other = vm.addr(3);
        vm.startPrank(owner); // startPrank
        weth = new WETH();
        deOrder = new DeOrder(address(weth), address(0));
        attackRefund = new AttackRefund(deOrder, weth);
        attackWithdraw = new AttackWithdraw(deOrder, weth);
        attackTransfer = new AttackTransfer(deOrder, weth);
        attackModifyOrder = new AttackModifyOrder(
            deOrder,
            weth,
            address(token0)
        );
        attackAbortOrder = new AttackAbortOrder(deOrder, weth);
        attackMulticallWithdraw = new AttackMulticallWithdraw(
            deOrder,
            weth
        );
        vm.deal(owner, 100 ether); // init eth balance
        vm.deal(issuer, 1 ether); // init eth balance
        vm.stopPrank();
    }

    function testFailAttackRefund() public {
        vm.startPrank(owner);
        deOrder.createOrder(0, owner, other, address(0), 100);
        deOrder.payOrder{value: 100 ether}(1, 100 ether); // payOrder
        vm.stopPrank();
        // console2.log(weth.totalSupply());

        vm.startPrank(issuer);
        attackRefund.attack{value: 1 ether}();
        vm.stopPrank();
        // console2.log(weth.totalSupply());
    }

    // permitStage
    // @Summary stage division
    function permitStage(
        address sign,
        uint256 _orderId,
        uint256[] memory _amounts,
        uint256[] memory _periods
    ) public returns (uint8 v, bytes32 r, bytes32 s) {
        PaymentType payType = PaymentType.Due;
        uint256 nonce = 0;
        uint256 deadline = 20000;
        bytes32 structHash = keccak256(
            abi.encode(
                deOrder.PERMITSTAGE_TYPEHASH(),
                _orderId,
                keccak256(abi.encodePacked(_amounts)),
                keccak256(abi.encodePacked(_periods)),
                payType,
                nonce,
                deadline
            )
        );
        bytes32 digest = ECDSA.toTypedDataHash(
            deOrder.DOMAIN_SEPARATOR(),
            structHash
        );
        // signature
        (v, r, s) = vm.sign(1, digest);
    }

    function testFailAttackWithdraw() public {
        console2.log(address(attackWithdraw).balance);
        vm.startPrank(owner);
        deOrder.createOrder(0, owner, other, address(0), 100);
        deOrder.payOrder{value: 100 ether}(1, 100 ether); // pay
        vm.stopPrank();
        // console2.log(weth.totalSupply());
        deOrder.createOrder(
            0,
            issuer,
            address(attackWithdraw),
            address(0),
            1 ether
        );
        amounts = [1 ether]; //100
        periods = [172800]; // two day
        vm.stopPrank();
        (uint8 v, bytes32 r, bytes32 s) = permitStage(
            issuer,
            2,
            amounts,
            periods
        ); // stage division
        attackWithdraw.start(amounts, periods, v, r, s);
        vm.startPrank(issuer);
        vm.deal(issuer, 2 ether); // init eth balance
        deOrder.payOrder{value: 1 ether}(2, 1 ether); // pay
        vm.warp(0); // init time
        deOrder.startOrder(2); // start order
        vm.warp(1728000); //init time
        vm.stopPrank();
        vm.startPrank(issuer);
        attackWithdraw.attack{value: 1 ether}();
        vm.stopPrank();

        console2.log(address(attackWithdraw).balance);
    }

    function testFailAttackTransfer() public {
        console2.log(address(attackWithdraw));
        console2.log(address(attackWithdraw).balance);
        vm.startPrank(owner);
        deOrder.createOrder(0, owner, other, address(0), 100);
        deOrder.payOrder{value: 100 ether}(1, 100 ether); // pay
        vm.stopPrank();
        // console2.log(weth.totalSupply());
        deOrder.createOrder(
            0,
            issuer,
            address(attackWithdraw),
            address(0),
            1 ether
        );
        vm.startPrank(issuer);
        attackTransfer.attack();
        vm.stopPrank();

        console2.log(address(attackWithdraw).balance);
    }

    function testFailAttackMulticallWithdraw() public {
        vm.startPrank(owner);
        deOrder.createOrder(0, owner, other, address(0), 100);
        deOrder.payOrder{value: 100 ether}(1, 100 ether); // pay
        vm.stopPrank();
        // console2.log(weth.totalSupply());
        deOrder.createOrder(
            0,
            issuer,
            address(attackMulticallWithdraw),
            address(0),
            1 ether
        );
        amounts = [1 ether]; //100
        periods = [172800]; // two day
        vm.stopPrank();
        (uint8 v, bytes32 r, bytes32 s) = permitStage(
            issuer,
            2,
            amounts,
            periods
        ); // stage division
        attackMulticallWithdraw.start(amounts, periods, v, r, s);
        vm.startPrank(issuer);
        vm.deal(issuer, 1 ether); // init eth balance
        deOrder.payOrder{value: 1 ether}(2, 1 ether); // pay
        vm.warp(0); //init time
        deOrder.startOrder(2); // start order
        vm.warp(1728000); //init time
        vm.stopPrank();
        vm.startPrank(issuer);
        attackMulticallWithdraw.attack();
        vm.stopPrank();

        console2.log(address(attackMulticallWithdraw).balance);
    }

    function testFailAttackModifyOrder() public {
        vm.startPrank(owner);
        deOrder.createOrder(0, owner, other, address(0), 100);
        deOrder.payOrder{value: 100 ether}(1, 100 ether); // pay
        vm.stopPrank();
        // console2.log(weth.totalSupply());

        vm.startPrank(issuer);
        attackRefund.attack{value: 1 ether}();
        vm.stopPrank();
        // console2.log(weth.totalSupply());
    }

    function testFailAttackAbortOrder() public {
        vm.startPrank(owner);
        deOrder.createOrder(0, owner, other, address(0), 100);
        deOrder.payOrder{value: 100 ether}(1, 100 ether); // pay
        vm.stopPrank();
        // console2.log(weth.totalSupply());

        amounts = [1 ether]; //100
        periods = [172800]; // two day
        vm.stopPrank();
        (uint8 v, bytes32 r, bytes32 s) = permitStage(
            issuer,
            2,
            amounts,
            periods
        ); // stage division
        vm.deal(issuer, 1 ether); // init eth balance
        attackAbortOrder.start{value: 1 ether}(issuer, amounts, periods, v, r, s);
        vm.startPrank(issuer);
        attackAbortOrder.attack();
        vm.stopPrank();

        console2.log(address(attackWithdraw).balance);
    }
}
