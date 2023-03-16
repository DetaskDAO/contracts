//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IOrderSBT {
  function mint(address who, uint orderId) external;
}