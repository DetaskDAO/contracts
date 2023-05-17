//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


struct TaskInfo {
    string title;
    string attachment;
    uint8 currency;
    uint128 budget;
    uint32 period;
    uint48 skills;
    uint32 timestamp;
    bool disabled;
}


interface ITask {
    function ownerOf(uint256 tokenId) external view returns (address);
    function tasks(uint256 tokenId)  external view returns (TaskInfo memory);
    function getTaskInfo(uint256 tokenId)  external view returns (string memory title,
        string memory attachment,
        uint8 currency,
        uint128 budget,
        uint32 period,
        uint48 skills,
        uint32 timestamp,
        bool disabled);
}

