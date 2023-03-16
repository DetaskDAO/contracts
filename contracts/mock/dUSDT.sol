//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract dUSDT is ERC20 {
    constructor() ERC20("DetaskUSDT", "dUSDT") {
        _mint(msg.sender, 10000000000 * 10 ** 6);
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }
}