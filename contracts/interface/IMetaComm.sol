//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMetaComm {
    function skills(uint i) external view returns (string memory);
    function skillAttributes(uint48 taskskills, uint i) external view returns (string memory);
    function dateTime(uint ts) external view returns (string memory datatime);
    function amountApprox(uint taskbudget, uint8 currency, bool escape) external view returns (string memory budget);
    function tokenAmountApprox(uint amount, address token, bool escape) external view returns (string memory budget);
}