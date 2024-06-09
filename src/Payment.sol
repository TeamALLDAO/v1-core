// SPDX-Licence-Identifier: UNLICENSED

pragma solidity 0.8.19;

import {IPayment} from "./interfaces/IPayment.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin/token/ERC20/utils/SafeERC20.sol";

/// @title Payment Contract
/// @author Mfon Stephen Nwa
/// @notice This contract handles payment between any two parties
contract Payments is IPayment {
    using SafeERC20 for IERC20;

    error PayerCannotBePayee();
    error PayeeCannotBeZeroAddress();
    error CurrencyCannotBeZeroAddress();
    error TotalPaymentAmountCannotBeZero();
    error OnlyPayerCanCancelPayment();
    error OnlyPayeeCanClaim();
    error InvalidPaymentState();
    error OnlyOwnerCanCall();

    uint24 public feePercent = 300;
    uint16 public constant BASIS_POINT = 10000;
    address immutable owner;
    uint256 public currentPaymentId;

    mapping(uint256 => Payment) public payments;

    constructor() {
        owner = msg.sender;
    }

    // Public Functions

    /// @inheritdoc	IPayment
    function calculateFee(uint256 amount) public view returns (uint256 feeAmount) {
        feeAmount = (amount * feePercent) / BASIS_POINT;
    }

    /// @inheritdoc	IPayment
    function calculateRemovedFee(uint256 amount) public view returns (uint256 feeRemovedAmount) {
        feeRemovedAmount = amount - ((amount * feePercent) / BASIS_POINT);
    }

    // External Functions

    /// @inheritdoc	IPayment
    function createPayment(PaymentRequest memory paymentRequest) external {
        _createPayment(msg.sender, paymentRequest);
    }

    /// @inheritdoc	IPayment
    function createPayments(PaymentRequest[] memory paymentRequests) external {
        for (uint256 i; i < paymentRequests.length; ++i) {
            _createPayment(msg.sender, paymentRequests[i]);
        }
    }

    /// @inheritdoc	IPayment
    function cancelPayment(uint256 paymentId) external {
        Payment memory payment = payments[paymentId];
        _enforceInState(PaymentState.Paying, payment);
        _cancelPayment(msg.sender, payment);
    }

    /// @inheritdoc IPayment
    function cancelPayments(uint256[] memory paymentIds) external {
        Payment memory payment;
        for (uint256 i; i < paymentIds.length; ++i) {
            payment = payments[paymentIds[i]];
            _enforceInState(PaymentState.Paying, payment);
            _cancelPayment(msg.sender, payment);
        }
    }

    /// @inheritdoc	IPayment
    function claimPayment(uint256 paymentId) external {
        Payment memory payment = payments[paymentId];
        _enforceInState(PaymentState.Paying, payment);
        _claimPayment(msg.sender, payment);
    }

    /// @inheritdoc	IPayment
    function claimPayments(uint256[] memory paymentIds) external {
        Payment memory payment;
        for (uint256 i; i < paymentIds.length; ++i) {
            payment = payments[paymentIds[i]];
            _enforceInState(PaymentState.Paying, payment);
            _claimPayment(msg.sender, payment);
        }
    }

    // Private Functions

    function _createPayment(address creator, PaymentRequest memory paymentRequest) private {
        uint256 id = currentPaymentId;
        uint256 totalPaymentAmount = (paymentRequest.numberOfInstallments * paymentRequest.amountPerInstallment);

        if (paymentRequest.payee == creator) revert PayerCannotBePayee();
        if (paymentRequest.payee == address(0)) revert PayeeCannotBeZeroAddress();
        if (paymentRequest.currency == address(0)) revert CurrencyCannotBeZeroAddress();
        if (totalPaymentAmount == 0) revert TotalPaymentAmountCannotBeZero();

        Payment memory payment = Payment({
            paymentState: PaymentState.Paying,
            payer: creator,
            paymentId: id,
            payee: paymentRequest.payee,
            currency: paymentRequest.currency,
            amountPerInstallment: calculateRemovedFee(paymentRequest.amountPerInstallment),
            numberOfInstallments: paymentRequest.numberOfInstallments,
            secondsBetweenInstallments: paymentRequest.secondsBetweenInstallments,
            nextInstallmentTimestamp: block.timestamp + paymentRequest.secondsDelay
        });

        uint256 feeAmount = calculateFee(totalPaymentAmount);
        IERC20(payment.currency).safeTransferFrom(creator, address(this), totalPaymentAmount);
        IERC20(payment.currency).safeTransfer(owner, feeAmount);

        currentPaymentId = id + 1;
        emit PaymentCreated(payment);
        _claimPayment(payment.payee, payment);
    }

    function _cancelPayment(address canceller, Payment memory payment) private {
        uint256 amountDue;
        uint256 installments = payment.numberOfInstallments;
        uint256 totalAmount = payment.amountPerInstallment * payment.numberOfInstallments;

        if (payment.payer != canceller) revert OnlyPayerCanCancelPayment();

        for (uint256 i; i < installments; ++i) {
            if (block.timestamp < payment.nextInstallmentTimestamp) break;
            amountDue += payment.amountPerInstallment;
            payment.nextInstallmentTimestamp += payment.secondsBetweenInstallments;
            payment.numberOfInstallments -= 1;
        }

        payment.paymentState = PaymentState.Cancelled;
        payments[payment.paymentId] = payment;

        if (amountDue > 0) {
            IERC20(payment.currency).safeTransfer(payment.payee, amountDue);
        }
        IERC20(payment.currency).safeTransfer(payment.payer, totalAmount - amountDue);
        emit PaymentCancelled(payment.paymentId, totalAmount);
    }

    function _claimPayment(address claimer, Payment memory payment) private {
        uint256 amountDue;
        uint256 installments = payment.numberOfInstallments;

        if (payment.payee != claimer) revert OnlyPayeeCanClaim();

        for (uint256 i; i < installments; ++i) {
            if (block.timestamp < payment.nextInstallmentTimestamp) break;
            amountDue += payment.amountPerInstallment;
            payment.nextInstallmentTimestamp += payment.secondsBetweenInstallments;
            payment.numberOfInstallments -= 1;
        }

        if (payment.numberOfInstallments == 0) {
            payment.paymentState = PaymentState.Paid;
        }
        payments[payment.paymentId] = payment;

        if (amountDue > 0) {
            IERC20(payment.currency).safeTransfer(payment.payee, amountDue);
        }
        emit PaymentClaimed(payment.paymentId, amountDue);
    }

    function _enforceInState(PaymentState paymentState, Payment memory payment) private pure {
        if (payment.paymentState != paymentState) revert InvalidPaymentState();
    }

    // View Functions

    function getPayment(uint256 paymentId) external view returns (Payment memory) {
        return payments[paymentId];
    }

    function getPayments(uint256[] memory paymentIds) external view returns (Payment[] memory) {
        Payment[] memory _payments = new Payment[](paymentIds.length);
        for (uint256 i; i < paymentIds.length; ++i) {
            _payments[i] = payments[paymentIds[i]];
        }
        return _payments;
    }

    // Owner Function

    function setFee(uint24 _feePercent) external {
        if (msg.sender != owner) revert OnlyOwnerCanCall();
        feePercent = _feePercent;
    }
}
