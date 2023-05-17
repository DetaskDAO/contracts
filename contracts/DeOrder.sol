// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


import "./interface/IOrderSBT.sol";
import './interface/IWETH9.sol';
import './interface/IPermit2.sol';
import './interface/IOrderVerifier.sol';

import "./DeOrderVerifier.sol";
import "./DeStage.sol";
import './Multicall.sol';



contract DeOrder is DeStage, DeOrderVerifier, Multicall, Ownable, ReentrancyGuard {
    error PermissionsError();
    error ProgressError();
    error UnSupportToken();

    uint private constant FEE_BASE = 10000;
    uint public fee = 500;
    address public feeTo;

    address public builderSBT;
    address public issuerSBT;

    IWETH9 public immutable WETH;
    IPermit2 public immutable PERMIT2;
    

    uint public currOrderId;

    mapping(uint => Order) private orders;

    mapping(address => bool) public supportTokens;

    event OrderCreated(uint indexed taskId, uint indexed orderId,  address issuer, address worker, address token, uint amount);
    event OrderModified(uint indexed orderId, address token, uint amount);
    event OrderStarted(uint indexed orderId, address who, uint payType);
    event OrderAbort(uint indexed orderId, address who, uint stageIndex);
    event Withdraw(uint indexed orderId, uint amount, uint stageIndex);
    event AttachmentUpdated(uint indexed orderId, string attachment);
    event FeeUpdated(uint fee, address feeTo);
    event SupportToken(address token, bool enabled);

    constructor(address _weth, address _permit2) {
        WETH = IWETH9(_weth);
        PERMIT2 = IPermit2(_permit2);

        feeTo = msg.sender;

        supportTokens[_weth] = true;
        supportTokens[address(0)] = true;
    }

    receive() external payable {
        assert(msg.sender == address(WETH)); // only accept ETH via fallback from the WETH contract
    }

    function createOrder(uint _taskId, address _issuer, address _worker, address _token, uint _amount) external payable {
        if(address(0) == _worker || address(0) == _issuer || _worker == _issuer) revert ParamError();
        safe96(_amount);

        if(!supportTokens[_token]) revert UnSupportToken();

        unchecked {
            currOrderId += 1;    
        }
        
        orders[currOrderId] = Order({
            taskId: _taskId,
            issuer: _issuer,
            worker: _worker,
            token: _token,  
            amount: uint96(_amount),
            progress: OrderProgess.Init,
            payType: PaymentType.Unknown,
            startDate: 0,
            payed: 0
        });

        emit OrderCreated(_taskId, currOrderId, _issuer, _worker, _token, _amount);
    }

    function getOrder(uint orderId) public override view returns (Order memory) {
        return orders[orderId];
    }

    function modifyOrder(uint orderId, address token, uint amount) external payable {
        safe96(amount);
        Order storage order = orders[orderId];
        if(order.progress >= OrderProgess.Ongoing) revert ProgressError();
        if(msg.sender != order.issuer) revert PermissionsError();
        if(!supportTokens[token]) revert UnSupportToken();
        
        // if change token , must refund
        if (orders[orderId].token != token && order.payed > 0) {
            refund(orderId, msg.sender, order.payed);
        }
        orders[orderId].token = token;
        orders[orderId].amount = uint96(amount);

        emit OrderModified(orderId, token, amount);
    }

    function permitStage(uint _orderId, uint[] memory _amounts, uint[] memory _periods,
        PaymentType payType,
        uint nonce,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s) public payable {
        
        Order storage order = orders[_orderId];
        if(order.progress >= OrderProgess.Ongoing) revert ProgressError();

        address signAddr = recoverPermitStage(_orderId, _amounts, _periods, uint(payType),
            nonce, deadline, v, r, s);
        
        roleCheck(order, signAddr);

        order.progress = OrderProgess.Staged;
        order.payType = payType;

        setStage(_orderId, _amounts, _periods);
    }

    function prolongStage(uint _orderId, uint _stageIndex, uint _appendPeriod,
        uint nonce, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        Order storage order = orders[_orderId];
        if(order.progress != OrderProgess.Ongoing) revert ProgressError();


        address signAddr = recoverProlongStage(_orderId, _stageIndex, _appendPeriod, nonce, deadline, v, r,  s );
        roleCheck(order, signAddr);
        prolongStage(_orderId, _stageIndex, _appendPeriod);
    }

    function appendStage(uint _orderId, uint amount, uint period, uint nonce, uint deadline, uint8 v, bytes32 r, bytes32 s) external payable {
        safe96(amount);
        Order storage order = orders[_orderId];
        if(order.progress != OrderProgess.Ongoing) revert ProgressError();

        address signAddr = recoverAppendStage(_orderId, amount, period, nonce, deadline, v, r, s);
        roleCheck(order, signAddr);

        order.amount += uint96(amount);
        if(order.payed < order.amount) revert AmountError(1);

        appendStage(_orderId, amount, period);
    }

    function roleCheck(Order storage order, address signAddr) internal {
        if((order.worker == msg.sender && signAddr == order.issuer) ||
            (order.issuer == msg.sender && signAddr == order.worker)) {
        } else {
            revert PermissionsError(); 
        } 
    }

    function payOrderWithPermit(uint orderId, uint amount, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        IERC20Permit(orders[orderId].token).permit(msg.sender, address(this), amount, deadline, v, r, s);
        payOrder(orderId, amount);
    }

    function payOrder(uint orderId, uint amount) public payable nonReentrant {
        Order storage order = orders[orderId];
        if (order.amount == 0){
            revert AmountError(0);
        }
        address token = order.token;
        safe96(amount);

        if (token == address(0)) {
            uint b = address(this).balance;
            IWETH9(WETH).deposit{value: b}();
            unchecked {
                order.payed += uint96(b);
            }
        } else {
            if(msg.value > 0) {
                revert AmountError(0);
            }
            
            SafeERC20.safeTransferFrom(IERC20(token), msg.sender, address(this), amount);
            order.payed += uint96(amount);
        }
    }

    function payOrderWithPermit2(
        uint orderId,
        uint256 amount,
        IPermit2.PermitTransferFrom calldata permit,
        bytes calldata signature
    ) external nonReentrant {
        safe96(amount);
        Order storage order = orders[orderId];
        if (permit.permitted.token != order.token || order.token == address(0)) {
            revert UnSupportToken(); 
        }
        
        // Transfer tokens from the caller to this contract.
        PERMIT2.permitTransferFrom(
            permit, // The permit message.
            // The transfer recipient and amount.
            IPermit2.SignatureTransferDetails({
                to: address(this),
                requestedAmount: amount
            }),
            // The owner of the tokens, which must also be
            // the signer of the message, otherwise this call
            // will fail.
            msg.sender,
            // The packed signature that was the result of signing
            // the EIP712 hash of `permit`.
            signature
        );

        order.payed += uint96(amount);
    }

    function updateAttachment(uint _orderId, string calldata _attachment) external {
        Order storage order = orders[_orderId];
        if(order.worker != msg.sender && order.issuer != msg.sender) revert PermissionsError();
        emit AttachmentUpdated(_orderId, _attachment);
    }

    function startOrder(uint _orderId) external payable {
        Order storage order = orders[_orderId];
        if(order.progress != OrderProgess.Staged || order.payType == PaymentType.Unknown) {
            revert ProgressError();
        }
        
        if(order.amount != stageTotalAmount(_orderId)) revert AmountError(0);
        if(order.payed < order.amount) revert AmountError(1);

        order.progress = OrderProgess.Ongoing;
        order.startDate = uint32(block.timestamp);
        emit OrderStarted(_orderId, msg.sender, uint(order.payType));
        
        startOrderStage(_orderId);
    }

    function confirmDelivery(uint _orderId, uint[] memory _stageIndexs) external {
        Order storage order = orders[_orderId];
        if(order.progress != OrderProgess.Ongoing) revert ProgressError();
        if(msg.sender != order.issuer) revert PermissionsError();

        for (uint i = 0; i < _stageIndexs.length;) {
            confirmDelivery(_orderId, _stageIndexs[i]);
            unchecked{ i++; }
        }
    }

    function abortOrder(uint _orderId) external nonReentrant {
        Order storage order = orders[_orderId];
        if(order.progress != OrderProgess.Ongoing) revert ProgressError();

        bool issuerAbort;
        if(order.worker == msg.sender) {
        } else if (order.issuer == msg.sender) {
            issuerAbort = true;
        } else {
            revert PermissionsError(); 
        } 

        (uint currStageIndex, uint issuerAmount, uint workerAmount) = 
            abortOrder(_orderId, issuerAbort);

        if (issuerAbort) {
            order.progress = OrderProgess.IssuerAbort;
        } else {
            order.progress = OrderProgess.WokerAbort;
        }

        doTransfer(order.token, order.issuer, issuerAmount);
        if (fee > 0) {
            uint feeAmount;
            unchecked {
                feeAmount = workerAmount * fee / FEE_BASE;
            }
            doTransfer(order.token, feeTo, feeAmount);
            doTransfer(order.token, order.worker, workerAmount - feeAmount);
        } else {
            doTransfer(order.token, order.worker, workerAmount);
        }

        emit OrderAbort(_orderId, msg.sender, currStageIndex);
    }

    function refund(uint _orderId, address _to, uint _amount) payable public nonReentrant {
        Order storage order = orders[_orderId];
        if(msg.sender != order.issuer) revert PermissionsError(); 
        safe96(_amount);
        order.payed -= uint96(_amount);
        if(order.progress >= OrderProgess.Ongoing) {
            if(order.payed < order.amount) revert AmountError(1);
        }

        doTransfer(order.token, _to, _amount);
    }

    function withdraw(uint _orderId, address to) external nonReentrant {
        Order storage order = orders[_orderId];
        if(order.worker != msg.sender) revert PermissionsError();
        if(order.progress != OrderProgess.Ongoing) revert ProgressError();

        (uint pending, uint nextStage) = pendingWithdraw(_orderId);
        if (pending > 0) {
            if (fee > 0) {
                uint feeAmount;
                unchecked {
                      feeAmount = pending * fee / FEE_BASE;
                }
                doTransfer(order.token, feeTo, feeAmount);
                doTransfer(order.token, to, pending - feeAmount);
                
            } else {
                doTransfer(order.token, to, pending);
            }
            
            withdrawStage(_orderId, nextStage);
        }
        
        if (nextStage > 0) {
            unchecked {
                emit Withdraw(_orderId, pending, nextStage - 1);
            }
        }
        
        if (nextStage >= stagesLength(_orderId)) {
            order.progress = OrderProgess.Done;

            if (builderSBT != address(0)) {
                IOrderSBT(builderSBT).mint(order.worker, _orderId);
            }

            if (issuerSBT != address(0)) {
                IOrderSBT(issuerSBT).mint(order.issuer, _orderId);
            }
        }

    }

    function doTransfer(address _token, address _to, uint _amount) private {
        if (_amount == 0) return;

        if (address(0) == _token) {
            IWETH9(WETH).withdraw(_amount);
            (bool success, ) = _to.call{value: _amount}(new bytes(0));
            require(success, 'ETH transfer failed');
        } else {
            SafeERC20.safeTransfer(IERC20(_token), _to, _amount);
        }
    }

    function setFeeTo(uint _fee, address _feeTo) external onlyOwner {
        fee = _fee;
        feeTo = _feeTo;
        emit FeeUpdated(_fee, _feeTo);
    } 

    function setSBT(address _builder, address _issuer) external onlyOwner {
        builderSBT = _builder;
        issuerSBT = _issuer;
    }

    function setSupportToken(address _token, bool enable) external onlyOwner {
        supportTokens[_token] = enable;
        emit SupportToken(_token, enable);
    }

}
