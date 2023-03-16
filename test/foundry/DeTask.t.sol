// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "contracts/DeTask.sol";
import {Utilities} from "./utils/Utilities.sol";
import {Mock} from "./mock/mock.sol";

contract DeTaskTest is Test {
    Mock internal mock;
    DeTask internal deTask;
    address owner; // owner
    address issuer; // issuer
    address worker; // worker
    address other; // other

    function setUp() public {
        mock = new Mock();
        // init user address
        owner = msg.sender;
        issuer = vm.addr(1);
        worker = vm.addr(2);
        other = vm.addr(3);

        vm.startPrank(owner); // startPrank
        deTask = new DeTask();
        vm.stopPrank();
        // console
        console.log(owner);
        console.log(issuer);
        console.log(worker);
    }

    // any to create task(pan)
    function testCreateTaskByDifferentPerson() public {
        string memory title;
        string memory attachment;
        uint8 currency;
        uint128 budget;
        uint32 period;
        uint48 skills;
        uint32 timestamp;
        bool disabled;
        // mock Task
        TaskInfo memory task = mock.mockOneTask(1);
        TaskInfo memory taskRecord;

        vm.startPrank(issuer); // issuer
        deTask.createTask(issuer, task);
        vm.stopPrank();
        (
            title,
            attachment,
            currency,
            budget,
            period,
            skills,
            timestamp,
            disabled
        ) = deTask.getTaskInfo(1);
        assertEq(bytes(title).length == 0, false);

        
        vm.startPrank(worker); // worker
        deTask.createTask(issuer, task);
        vm.stopPrank();
        (
            title,
            attachment,
            currency,
            budget,
            period,
            skills,
            timestamp,
            disabled
        ) = deTask.getTaskInfo(2);
         assertEq(bytes(title).length == 0, false);
       
        vm.startPrank(other); // other
        deTask.createTask(other, task);
        vm.stopPrank();
        (
            title,
            attachment,
            currency,
            budget,
            period,
            skills,
            timestamp,
            disabled
        ) = deTask.getTaskInfo(3);
         assertEq(bytes(title).length == 0, false);
    }

    // testCreateTask
    // @Summary create task
    function testCreateTask() public {
        // TaskInfo
        TaskInfo memory task = mock.mockOneTask(1);
        // create Task
        vm.startPrank(issuer); // issuer
        deTask.createTask(issuer, task);
        vm.stopPrank();
        // getTaskInfo
        (
            string memory title,
            string memory attachment,
            uint8 currency,
            uint128 budget,
            uint32 period,
            uint48 skills,
            uint32 timestamp,
            bool disabled
        ) = deTask.getTaskInfo(1);
        assertEq(task.title, title);
        assertEq(task.attachment, attachment);
        assertEq(task.currency, currency);
        assertEq(task.budget, budget);
        assertEq(task.period, period);
        assertEq(task.skills, skills);
        assertEq(task.timestamp, timestamp);
        assertEq(false, disabled);
    }

    // testCannotModifyTaskNotIssuer
    // @Summary incorrect addressTask
    // @Failure modifyTask No permission.
    function testCannotModifyTaskNotIssuer() public {
        testCreateTask();
        TaskInfo memory task = mock.mockOneTask(2);
        vm.expectRevert(bytes("No permission."));
        deTask.modifyTask(1, task);
    }
    // taskid not exists(pan)
    function testModifyTaskUseTaskIdNotExist() public {
        testCreateTask();
        TaskInfo memory task = mock.mockOneTask(2);
        vm.startPrank(issuer);
        vm.expectRevert(bytes("ERC721: invalid token ID"));
        deTask.modifyTask(2, task);
        vm.stopPrank();
    }
    
    // testModifyTask
    // @Summary modify Task
    function testModifyTask() public {
        testCreateTask();
        TaskInfo memory task = mock.mockOneTask(3);
        // modify Task
        task.timestamp = 123;
        vm.startPrank(issuer); // issuer
        deTask.modifyTask(1, task);
        vm.stopPrank();
        // getTaskInfo
        (
            string memory title,
            string memory attachment,
            uint8 currency,
            uint128 budget,
            uint32 period,
            uint48 skills,
            ,
            bool disabled
        ) = deTask.getTaskInfo(1);
        assertEq(task.title, title);
        assertEq(task.attachment, attachment);
        assertEq(task.currency, currency);
        assertEq(task.budget, budget);
        assertEq(task.period, period);
        assertEq(task.skills, skills);
        assertEq(task.disabled, disabled);
    }
    // getTaskInfo
    // taskid not exists(pan)
    function testGetTaskInfoUseNotExistTaskId() public {
        string memory title;
        string memory attachment;
        uint8 currency;
        uint128 budget;
        uint32 period;
        uint48 skills;
        uint32 timestamp;
        bool disabled;

        testCreateTask();
        vm.startPrank(issuer);
        (
            title,
            attachment,
            currency,
            budget,
            period,
            skills,
            timestamp,
            disabled
        ) = deTask.getTaskInfo(1);
        assertEq(bytes(title).length == 0, false);
        vm.stopPrank();
        vm.startPrank(worker);
               (
            title,
            attachment,
            currency,
            budget,
            period,
            skills,
            timestamp,
            disabled
        ) = deTask.getTaskInfo(1);
        assertEq(bytes(title).length == 0, false);
        vm.stopPrank();
        vm.startPrank(other);
               (
            title,
            attachment,
            currency,
            budget,
            period,
            skills,
            timestamp,
            disabled
        ) = deTask.getTaskInfo(1);
        assertEq(bytes(title).length == 0, false);
        vm.stopPrank();

    }

    // testCannotApplyFor
    // @Summary apply Task fail
    function testCannotApplyFor() public {
        testCreateTask();
        // apply yourself
        vm.expectRevert(bytes("Not apply for orders yourself."));
        deTask.applyFor(issuer, 1, 100);
        testModifyTask();
        // apply closed task
        vm.expectRevert(bytes("The apply switch is closed."));
        deTask.applyFor(worker, 1, 100);
        // not enought fee
        testUpdateFeeReceiver();
        vm.deal(worker, 20);
        vm.startPrank(worker); // worker
        vm.expectRevert(bytes("low fee"));
        deTask.applyFor{value: 9}(worker, 1, 100);
        vm.stopPrank();
    }
    // apply address zero and more
    event ApplyFor(uint indexed taskId, address indexed worker, uint cost);
    function testFailApplyForApplicantNotExist() public {
        
        testCreateTask();
        // zero address
        address dre = 0x0000000000000000000000000000000000000000;
        vm.expectEmit(true, true, false, true);
        emit ApplyFor(1,0x0000000000000000000000000000000000000001,100);
        deTask.applyFor(dre, 1, 100);
    }


    // apply not exists id
    function testApplyForTaskIdNotExist() public {
        
        testCreateTask();
        vm.expectRevert(bytes("ERC721: invalid token ID"));
        deTask.applyFor(worker, 2, 100);
    }
    // apply value > 0
    function testFailApplyForCostNotEnought() public {
        testCreateTask();
        // vm.expectRevert(bytes("ERC721: invalid token ID"));
        vm.expectEmit(true, true, false, true);
        emit ApplyFor(1,worker,100);
        deTask.applyFor(worker, 1, 0);
    }

    // testApplyFor
    // @Summary apply Task
    function testApplyFor() public {
        testCreateTask();
        vm.startPrank(worker); // worker
        deTask.applyFor{value: 0}(worker, 1, 100);
        vm.stopPrank();
    }

    // testCannotUpdateFeeReceiver
    // @Summary not owner to change
    function testCannotUpdateFeeReceiver() public {
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        deTask.updateFeeReceiver(1, 1, worker);
    }

    // testCannotUpdateFeeReceiver
    // @Summary change fee
    function testUpdateFeeReceiver() public {
        vm.startPrank(owner);
        deTask.updateFeeReceiver(10, 10, owner);
        vm.stopPrank();
    }

    // testCannotCancelApply
    // @Summary cancel apply not the task owner
    function testCannotCancelApply() public {
        testApplyFor();
        vm.expectRevert(bytes("Not applied."));
        // vm.startPrank(issuer);
        deTask.cancelApply(1);
        // vm.stopPrank();
    }

    // apply not exists task
    function testCancelApplyTaskIdNotExist() public {
        testApplyFor();
        vm.expectRevert(bytes("Not applied."));
        // vm.startPrank(issuer);
        vm.startPrank(worker);
        deTask.cancelApply(2);
        vm.stopPrank();
    }

    // testCancelApply
    // @Summary cancel apply
    function testCancelApply() public {
        testApplyFor();
        vm.startPrank(worker);
        deTask.cancelApply(1);
        vm.stopPrank();
    }

    // testCannotApplyAndCancel
    // @Summary not apply owner && not enought fee
    function testCannotApplyAndCancel() public {
        testCreateTask();
        testCreateTask();
        uint256[] memory _taskIds = new uint256[](2);
        uint256[] memory costs = new uint256[](2);
        uint256[] memory cancelIds = new uint256[](1);
        _taskIds[0] = 1;
        _taskIds[1] = 2;
        costs[0] = 1;
        cancelIds[0] = 1;
        // not enought fee
        testUpdateFeeReceiver();
        vm.deal(worker, 20);
        vm.startPrank(worker); // worker
        vm.expectRevert(bytes("low fee"));
        deTask.applyAndCancel{value: 19}(worker, _taskIds, costs, cancelIds);
        vm.stopPrank();
        // not apply owner
        vm.expectRevert(bytes("Not applied."));
        deTask.applyAndCancel{value: 20}(worker, _taskIds, costs, cancelIds);
    }

    // testApplyAndCancel
    // @Summary apply && cancel apply
    function testApplyAndCancel() public {
        testCreateTask();
        testCreateTask();
        uint256[] memory _taskIds = new uint256[](2);
        uint256[] memory costs = new uint256[](2);
        uint256[] memory cancelIds = new uint256[](0);
        _taskIds[0] = 1;
        _taskIds[1] = 2;
        costs[0] = 1;
        costs[1] = 1; // same to no apply
        // not enought fee
        testUpdateFeeReceiver();
        vm.deal(worker, 20);
        vm.startPrank(worker); // worker
        // apply
        deTask.applyAndCancel{value: 20}(worker, _taskIds, costs, cancelIds);
        // cancel apply
        _taskIds = new uint256[](0);
        costs = new uint256[](0);
        cancelIds = new uint256[](2);
        cancelIds[0] = 1;
        cancelIds[1] = 2;
        deTask.applyAndCancel(worker, _taskIds, costs, cancelIds);
        vm.stopPrank();
    }

    // testCannotDisableTask
    // @Summary incorrect not apply owner && same status
    function testCannotDisableTask() public {
        testCreateTask();
        // not apply owner
        vm.expectRevert(bytes("No permission."));
        deTask.disableTask(1, true);
        // same status
        vm.startPrank(issuer); // issuer
        vm.expectRevert(bytes("same state."));
        deTask.disableTask(1, false);
        vm.stopPrank();
    }

    // testDisableTask
    // @Summary disable task
    function testDisableTask() public {
        testCreateTask();
        vm.startPrank(issuer); // issuer
        deTask.disableTask(1, true);
        vm.stopPrank();
        (, , , , , , , bool disabled) = deTask.getTaskInfo(1);
        assertEq(disabled, true);
    }

    // TODO: ERROR
    // testTransferFee
    // @Summary fee
    function testTransferFee() public {
        vm.deal(issuer, 20 ether);
        // vm.startPrank(issuer); // issuer
        // TransferHelper.safeTransferETH(owner, 1);
        // deTask.transferFee(1);
        // console.log(address(worker).balance);
        // (bool success, ) = address(worker).call{value: 1}(new bytes(0));
        // require(
        //     success,
        //     "TransferHelper::safeTransferETH: ETH transfer failed"
        // );
        //
        // vm.stopPrank();
    }

    // testCannotSetMetaContract
    // @Summary not owner && set to zero address
    function testCannotSetMetaContract() public {
        // not owner
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        deTask.setMetaContract(
            address(0xd2EeE6cB28C99767BA7F8469C3C621033bb09C77)
        );
        // set to zero address
        vm.startPrank(owner);
        vm.expectRevert(bytes("zero address"));
        deTask.setMetaContract(address(0));
        vm.stopPrank();
    }

    // testSetMetaContract
    // @Summary set Meta contract address
    function testSetMetaContract() public {
        address addr = address(0xd2EeE6cB28C99767BA7F8469C3C621033bb09C77);
        vm.startPrank(owner);
        deTask.setMetaContract(addr);
        vm.stopPrank();
        assertEq(deTask.meta(), addr);
    }

    // function testTokenURI()public{
    //     console.log(deTask.tokenURI(1));
    // }

    // set fee to address
    function testUpdateFeeReceiverNotOwner() public {
        vm.startPrank(other);
        vm.expectRevert("Ownable: caller is not the owner");
        deTask.updateFeeReceiver(20,20,issuer);
        vm.stopPrank();
    }
}
