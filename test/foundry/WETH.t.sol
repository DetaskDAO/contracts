// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "contracts/mock/WETH.sol";

contract WETHTest is Test {
    WETH internal _weth;
    address owner; // owner
    address issuer; // issuer
    address worker; // worker
    address other; // other

    function setUp() public {
        owner = msg.sender;
        issuer = vm.addr(1);
        worker = vm.addr(2);
        other = vm.addr(3);
        vm.startPrank(owner); // startPrank
        _weth = new WETH();
        vm.stopPrank();
        vm.deal(issuer, 1000);
        vm.deal(worker, 1000);
    }

    function testDeposit() public {
        vm.startPrank(issuer);
        _weth.deposit{value: 100}();
        vm.stopPrank();
        assertEq(address(_weth).balance, 100);
        assertEq(_weth.totalSupply(), 100);
    }

    function testFailDeposit() public {
        vm.startPrank(issuer);
        _weth.deposit{value: 10000 ether}();
        vm.stopPrank();
    }

    function testWithdraw() public {
        vm.startPrank(issuer);
        uint256 balance = issuer.balance; // issuer amount
        _weth.deposit{value: 100}();
        assertEq(issuer.balance, balance - 100);
        assertEq(address(_weth).balance, 100);
        assertEq(_weth.totalSupply(), 100);
        assertEq(_weth.balanceOf(issuer), 100);
        // withdraw 50
        _weth.withdraw(50);
        assertEq(issuer.balance, balance - 50);
        assertEq(address(_weth).balance, 50);
        assertEq(_weth.totalSupply(), 50);
        assertEq(_weth.balanceOf(issuer), 50);
        // withdraw all
        _weth.withdraw(50);
        vm.stopPrank();
        assertEq(issuer.balance, balance);
        assertEq(address(_weth).balance, 0);
        assertEq(_weth.totalSupply(), 0);
        assertEq(_weth.balanceOf(issuer), 0);
        vm.stopPrank();
    }

    function testFailWithdraw() public {
        vm.startPrank(issuer);
        uint256 balance = issuer.balance; // issuer amount
        _weth.deposit{value: 100}();
        assertEq(issuer.balance, balance - 100);
        assertEq(address(_weth).balance, 100);
        assertEq(_weth.totalSupply(), 100);
        vm.stopPrank();
        // other withdraw
        _weth.withdraw(50);
    }

    function testTransfer() public {
        vm.startPrank(issuer);
        uint256 balance = issuer.balance; // issuer amount
        _weth.deposit{value: 100}();
        assertEq(issuer.balance, balance - 100);
        assertEq(address(_weth).balance, 100);
        assertEq(_weth.totalSupply(), 100);
        assertEq(_weth.balanceOf(issuer), 100);

        // transfer
        _weth.transfer(worker, 50);
        assertEq(issuer.balance, balance - 100);
        assertEq(_weth.balanceOf(issuer), 50);
        assertEq(_weth.balanceOf(worker), 50);
        assertEq(address(_weth).balance, 100);
        assertEq(_weth.totalSupply(), 100);

        vm.stopPrank();
    }

    function testTransferFrom() public {
        vm.startPrank(issuer);
        uint256 balance = issuer.balance; // issuer amount
        _weth.deposit{value: 100}();
        assertEq(issuer.balance, balance - 100);
        assertEq(address(_weth).balance, 100);
        assertEq(_weth.totalSupply(), 100);
        assertEq(_weth.balanceOf(issuer), 100);

        // transfer
        _weth.transferFrom(issuer, worker, 50);
        assertEq(issuer.balance, balance - 100);
        assertEq(_weth.balanceOf(issuer), 50);
        assertEq(_weth.balanceOf(worker), 50);
        assertEq(address(_weth).balance, 100);
        assertEq(_weth.totalSupply(), 100);

        vm.stopPrank();
    }

    function testFailTransferFrom() public {
        vm.startPrank(issuer);
        uint256 balance = issuer.balance; // issuer amount
        _weth.deposit{value: 100}();
        assertEq(issuer.balance, balance - 100);
        assertEq(address(_weth).balance, 100);
        assertEq(_weth.totalSupply(), 100);
        assertEq(_weth.balanceOf(issuer), 100);
        vm.stopPrank();
        // transfer other
        _weth.transferFrom(issuer, worker, 50);
    }

    function testFailTransferFrom2() public {
        vm.startPrank(issuer);
        uint256 balance = issuer.balance; // issuer amount
        _weth.deposit{value: 100}();
        assertEq(issuer.balance, balance - 100);
        assertEq(address(_weth).balance, 100);
        assertEq(_weth.totalSupply(), 100);
        assertEq(_weth.balanceOf(issuer), 100);
        vm.stopPrank();
        // other
        vm.startPrank(worker);
        uint256 balance2 = worker.balance; // issuer amount
        _weth.deposit{value: 100}();
        assertEq(worker.balance, balance2 - 100);
        assertEq(address(_weth).balance, 200);
        assertEq(_weth.totalSupply(), 200);
        assertEq(_weth.balanceOf(worker), 100);
        vm.stopPrank();
        // not enough amount
        vm.startPrank(issuer);
        _weth.transferFrom(issuer, worker, 120);
        vm.stopPrank();
    }

    function testApprove() public {
        uint256 balanceIssuer = issuer.balance;
        uint256 balanceWorker = worker.balance;
        uint256 balanceOther = other.balance;
        vm.startPrank(issuer);
        _weth.deposit{value: 100}();
        _weth.approve(worker, 50);
        vm.stopPrank();
        vm.startPrank(worker);
        _weth.transferFrom(issuer, other, 50);
        vm.stopPrank();
        assertEq(issuer.balance, balanceIssuer - 100);
        assertEq(worker.balance, balanceWorker);
        assertEq(other.balance, balanceOther);
        assertEq(_weth.balanceOf(issuer), 50);
        assertEq(_weth.balanceOf(worker), 0);
        assertEq(_weth.balanceOf(other), 50);
    }

    function testFailApprove() public {
        vm.startPrank(issuer);
        _weth.deposit{value: 100}();
        _weth.approve(worker, 50);
        vm.stopPrank();
        vm.startPrank(worker);
        _weth.transferFrom(issuer, other, 51);
        vm.stopPrank();
    }

    function testFailApprove2() public {
        vm.startPrank(issuer);
        _weth.deposit{value: 100}();
        _weth.approve(worker, 50);
        vm.stopPrank();
        vm.startPrank(worker);
        _weth.transferFrom(issuer, other, 20);
        _weth.transferFrom(issuer, other, 29);
        _weth.transferFrom(issuer, other, 2);
        vm.stopPrank();
    }
}
