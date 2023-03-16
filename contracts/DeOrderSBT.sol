//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interface/IOrder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./SBTBase.sol";
import "./interface/IMetadata.sol";


contract DeOrderSBT is SBTBase, Ownable {

    error InvalidCaller();

    address public deOrder;
    address public meta;

    constructor(address _order, string memory _name, string memory _symbol) SBTBase(_name, _symbol) {
        deOrder = _order; 
    }

    modifier onlyDeorder() {
        if(msg.sender != deOrder) revert InvalidCaller(); 
        _;
    }

    function mint(address who, uint orderId) external onlyDeorder {
        _mint(who, orderId);
    }

    function setMetaContract(address _meta) external onlyOwner {
        require(_meta != address(0), "zero address");
        meta = _meta;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return IMetadata(meta).tokenURI(tokenId);
    }
}