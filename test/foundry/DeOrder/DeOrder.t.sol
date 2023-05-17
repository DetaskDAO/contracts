// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "contracts/DeOrder.sol";
import "contracts/mock/WETH.sol";
import "contracts/libs/ECDSA.sol";
import "contracts/interface/IOrder.sol";
import {Utilities} from "../utils/Utilities.sol";
import {Permit2Sign} from "../utils/Permit2Sign.sol";
import {Permit2} from "permit2/Permit2.sol";
import {MockERC20} from "../mock/MockERC20.sol";
import {IPermit2} from "contracts/interface/IPermit2.sol";

contract DeOrderTest is Test, Utilities, Permit2Sign {
    MockERC20 token0;
    Permit2 permit2;
    IPermit2 internal PERMIT2;
    DeOrder internal deOrder;
    WETH internal _weth;
    bytes32 DOMAIN_SEPARATOR;
    address owner; // owner
    address issuer; // issuer
    address worker; // worker
    address other; // other
    address zero = address(0);

    uint[] amounts = [50, 50];
    uint[] periods = [1000, 1000];
    uint[] stageIndexs = [0, 1, 2];
    error ParamError();
    event SupportToken(address token, bool enabled);
    event OrderModified(uint indexed orderId, address token, uint amount);
    event AttachmentUpdated(uint indexed orderId, string attachment);

    // address _permit2 = 0x250182E0C0885e355E114f2FcCC03292aa6Ea2fC;
    function setUp() public {
        token0 = new MockERC20("Test0", "TEST0", 18);
        permit2 = new Permit2{salt: 0x00}();
        DOMAIN_SEPARATOR = permit2.DOMAIN_SEPARATOR();
        PERMIT2 = IPermit2(address(permit2));
        // init user address
        owner = msg.sender;
        issuer = vm.addr(1);
        worker = vm.addr(2);
        other = vm.addr(3);

        vm.startPrank(owner); // startPrank
        _weth = new WETH();
        deOrder = new DeOrder(
            address(_weth),
            address(permit2)
        );
        vm.stopPrank();
        // console
        console.log(owner);
        console.log(issuer);
        console.log(worker);
        token0.mint(issuer, 100 ** 18);
        vm.startPrank(issuer);
        token0.approve(address(permit2), type(uint256).max); // approve
        token0.approve(address(deOrder), type(uint256).max); // approve
        vm.stopPrank();
        vm.deal(issuer, 1000 ether); // init eth balance
    }

    // createOrder
    // @Summary create order
    function createOrder(address who, address _token, uint _amount) public {
        vm.startPrank(who); // issuer
        deOrder.createOrder(64, issuer, worker, address(_token), _amount);
        vm.stopPrank();
    }

    // modifyOrder
    // @Summary modify Order
    function modifyOrder(
        address who,
        uint orderId,
        address token,
        uint amount
    ) public {
        vm.startPrank(who);
        vm.expectEmit(true, false, false, true);
        emit OrderModified(orderId, token, amount);
        deOrder.modifyOrder(orderId, token, amount);
        vm.stopPrank();
    }

    // permitStage
    // @Summary stage division
    function permitStage(
        address sign,
        address submit,
        uint256 _orderId,
        uint256[] memory _amounts,
        uint256[] memory _periods,
        bytes memory payTypeString,
        bytes memory expectRevert
    ) public {
        PaymentType payType = PaymentType.Unknown;
        if (keccak256(payTypeString) == keccak256("Confirm")) {
            payType = PaymentType.Confirm;
        } else if (keccak256(payTypeString) == keccak256("Due")) {
            payType = PaymentType.Due;
        } else {
            revert ParamError();
        }
        uint256 nonce = deOrder.nonces(sign, _orderId);
        uint256 deadline = 200;
        bytes32 structHash = keccak256(
            abi.encode(
                deOrder.PERMITSTAGE_TYPEHASH(),
                _orderId,
                keccak256(abi.encodePacked(_amounts)),
                keccak256(abi.encodePacked(_periods)),
                payType,
                nonce,
                deadline
            )
        );
        bytes32 digest = ECDSA.toTypedDataHash(
            deOrder.DOMAIN_SEPARATOR(),
            structHash
        );
        // signature
        uint8 v;
        bytes32 r;
        bytes32 s;
        if (sign == issuer) {
            (v, r, s) = vm.sign(1, digest);
        } else if (sign == worker) {
            (v, r, s) = vm.sign(2, digest);
        } else {
            (v, r, s) = vm.sign(3, digest);
        }
        // submit
        vm.startPrank(submit);
        if (expectRevert.length != 0) {
            vm.expectRevert(expectRevert);
        }
        deOrder.permitStage(
            _orderId,
            _amounts,
            _periods,
            payType,
            nonce,
            deadline,
            v,
            r,
            s
        );
        vm.stopPrank();
    }

    function prolongStage(
        address sign,
        address submit,
        uint256 _orderId,
        uint256 _stageIndex,
        uint256 _appendPeriod,
        bytes memory expectRevert
    ) public {
        uint256 nonce = deOrder.nonces(sign, _orderId);
        uint256 deadline = 1000000;
        bytes32 structHash = keccak256(
            abi.encode(
                deOrder.PERMITPROSTAGE_TYPEHASH(),
                _orderId,
                _stageIndex,
                _appendPeriod,
                nonce,
                deadline
            )
        );
        bytes32 digest = ECDSA.toTypedDataHash(
            deOrder.DOMAIN_SEPARATOR(),
            structHash
        );
        // signature
        uint8 v;
        bytes32 r;
        bytes32 s;
        if (sign == issuer) {
            (v, r, s) = vm.sign(1, digest);
        } else if (sign == worker) {
            (v, r, s) = vm.sign(2, digest);
        } else {
            (v, r, s) = vm.sign(3, digest);
        }
        vm.startPrank(submit);
        if (expectRevert.length != 0) {
            vm.expectRevert(expectRevert);
        }
        deOrder.prolongStage(
            _orderId,
            _stageIndex,
            _appendPeriod,
            nonce,
            deadline,
            v,
            r,
            s
        );
        vm.stopPrank();
    }

    // appendStage
    // @Summary append Stage
    function appendStage(
        address sign,
        address submit,
        uint256 _orderId,
        uint256 amount,
        uint256 period,
        bytes memory expectRevert
    ) public {
        uint256 nonce = deOrder.nonces(sign, _orderId);
        uint256 deadline = 1000000;
        bytes32 structHash = keccak256(
            abi.encode(
                deOrder.PERMITAPPENDSTAGE_TYPEHASH(),
                _orderId,
                amount,
                period,
                nonce,
                deadline
            )
        );
        bytes32 digest = ECDSA.toTypedDataHash(
            deOrder.DOMAIN_SEPARATOR(),
            structHash
        );
        // signature
        uint8 v;
        bytes32 r;
        bytes32 s;
        if (sign == issuer) {
            (v, r, s) = vm.sign(1, digest);
        } else if (sign == worker) {
            (v, r, s) = vm.sign(2, digest);
        } else {
            (v, r, s) = vm.sign(3, digest);
        }
        vm.startPrank(submit);
        if (expectRevert.length != 0) {
            vm.expectRevert(expectRevert);
        }
        deOrder.appendStage(_orderId, amount, period, nonce, deadline, v, r, s);
        vm.stopPrank();
    }

    // startOrder
    // @Summary start order
    function startOrder(address who) public {
        vm.startPrank(who);
        deOrder.startOrder(1);
        vm.stopPrank();
    }

    // @Summary pay
    function payOrder(address who, uint256 amount, address _token) public {
        vm.startPrank(who);
        if (_token == address(0)) {
            deOrder.payOrder{value: amount}(1, amount);
        } else {
            deOrder.payOrder(1, amount);
        }
        vm.stopPrank();
    }

    // abortOrder
    // @Summary abort order
    function abortOrder(address who, uint256 _orderId) public {
        vm.startPrank(who);
        deOrder.abortOrder(_orderId);
        vm.stopPrank();
    }

    // setSupportToken set support Token
    function setSupportToken(address who, address _token, bool enable) public {
        vm.startPrank(who);
        vm.expectEmit(false, false, false, true);
        emit SupportToken(address(_token), enable);
        deOrder.setSupportToken(_token, enable);
        vm.stopPrank();
    }

    function confirmDelivery(
        address who,
        uint _orderId,
        uint[] memory _stageIndexs
    ) public {
        vm.startPrank(who);
        deOrder.confirmDelivery(_orderId, _stageIndexs);
        vm.stopPrank();
    }

    // withdraw
    function withdraw(address who, uint _orderId, address to) public {
        vm.startPrank(who);
        deOrder.withdraw(_orderId, to);
        vm.stopPrank();
    }

    function updateAttachment(
        address who,
        uint _orderId,
        string memory _attachment,
        bytes memory expectRevert
    ) public {
        vm.startPrank(who);
        if (expectRevert.length != 0) {
            vm.expectRevert(expectRevert);
        } else {
            vm.expectEmit(true, true, true, true);
            emit AttachmentUpdated(_orderId, _attachment);
        }
        deOrder.updateAttachment(_orderId, _attachment);
        vm.stopPrank();
    }

    // payOrderWithPermit2
    // @Summary pay order with Permit2
    function payOrderWithPermit2(
        address who,
        uint orderId,
        uint256 amount,
        address _token
    ) public {
        uint256 nonce = 0;
        IPermit2.PermitTransferFrom memory permit = defaultERC20PermitTransfer(
            _token,
            nonce
        );
        // signature
        bytes memory sig = getPermitTransferSignature(
            permit,
            DOMAIN_SEPARATOR,
            address(deOrder)
        );
        vm.startPrank(who);
        deOrder.payOrderWithPermit2(orderId, amount, permit, sig);
        vm.stopPrank();
    }

    function refund(
        address who,
        uint _orderId,
        address _to,
        uint _amount
    ) public {
        vm.startPrank(who);
        deOrder.refund(_orderId, _to, _amount);
        vm.stopPrank();
    }
}
