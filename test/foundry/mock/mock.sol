// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "contracts/interface/ITask.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Mock is Test {
    // mockTask
    // @Summary mock test Task
    // @Param uint256 num
    // @Return: TaskInfo[] memory task
    function mockTask(
        uint256 num
    ) public view returns (TaskInfo[] memory task) {
        task = new TaskInfo[](num);

        for (uint256 i = 0; i < num; i++) {
            bool disabled = false;
            if (i % 2 == 0) {
                disabled = true;
            }
            task[i] = TaskInfo({
                title: string.concat("title\u6807\u9898", Strings.toString(i)),
                attachment: string.concat(
                    "attachment\u9644\u4ef6",
                    Strings.toString(i)
                ),
                currency: uint8(i),
                budget: uint128(i),
                period: uint32(i),
                skills: uint32(i),
                timestamp: uint32(block.timestamp),
                disabled: disabled
            });
        }
    }

    // mockOneTask
    // @Summary mock one Task
    // @Param uint256 index
    // @Return: TaskInfo memory task
    function mockOneTask(
        uint256 index
    ) public view returns (TaskInfo memory task) {
        require(index > 0, "index must be greater than 0");
        TaskInfo[] memory taskList = mockTask(index);
        return taskList[index - 1];
    }
}
