// SPDX-Licence-Identifier: UNLICENSED

pragma solidity 0.8.19;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import {IStorage} from "./interfaces/IStorage.sol";

/// @title the contract that handles storage subscriptions
/// @author Mfon Stephen Nwa
contract Storage is IStorage {
    using SafeERC20 for IERC20;

    error OnlyOwnerCanCall();
    error CurrencyCannotBeZeroAddress();

    address public immutable owner;
    uint256 public constant BASIS_POINT = 10000;
    address public currency;
    uint256 public priceNumerator;

    mapping(address => uint256) suscriptions;

    constructor(address _currency) {
        currency = _currency;
        priceNumerator = 1;
        owner = msg.sender;
    }

    /// @inheritdoc	IStorage
    function subscribe(uint256 amount) external {
        uint256 userExpiration = viewSubscription(msg.sender);
        IERC20(currency).safeTransferFrom(msg.sender, address(this), (amount * priceNumerator) / BASIS_POINT);
        suscriptions[msg.sender] = userExpiration + amount;
        emit StorageSuscribed(msg.sender, amount);
    }

    /// @inheritdoc	IStorage
    function viewSubscription(address user) public view returns (uint256) {
        uint256 userSubscriptionExpiration = suscriptions[user];
        return userSubscriptionExpiration > block.timestamp ? userSubscriptionExpiration : block.timestamp;
    }

    /// @inheritdoc	IStorage
    function isSubscribed(address user) external view returns (bool status) {
        return suscriptions[user] > block.timestamp;
    }

    /// @inheritdoc	IStorage
    function setCurrency(address _currency) external {
        if (msg.sender != owner) revert OnlyOwnerCanCall();
        if (currency == address(0)) revert CurrencyCannotBeZeroAddress();
        currency = _currency;
    }

    /// @inheritdoc	IStorage
    function setPrice(uint256 numerator) external {
        if (msg.sender != owner) revert OnlyOwnerCanCall();
        priceNumerator = numerator;
    }

    /// @inheritdoc	IStorage
    function getPrice() external view returns (uint256) {
        return priceNumerator / BASIS_POINT;
    }
}
