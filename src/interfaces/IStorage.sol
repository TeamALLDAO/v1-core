// SPDX-Licence-Identifier: UNLICENSED

pragma solidity 0.8.19;

/// @title the interface for the Storage contract
/// @author Mfon Stephen Nwa
interface IStorage {
    /// @notice the event emitted when a user subscribes for
    /// @param user the address of the user
    /// @param duration the duration the user subscribes for
    event StorageSuscribed(address user, uint256 duration);

    /// @notice the function to subscribe for storage
    /// @param amount the amount of seconds to subscribe for
    function subscribe(uint256 amount) external;

    /// @notice function to get the user subscription
    /// @param user the user address
    /// @return `uint256`
    function viewSubscription(address user) external view returns (uint256);

    /// @notice function to check if a user has an active subscription
    /// @param user address of the user
    /// @return status a boolean indicating of the user has an active subscription
    function isSubscribed(address user) external view returns (bool status);

    /// @notice function to set the currency for subscribing
    /// @param _currency the token used in subscrining
    function setCurrency(address _currency) external;

    /// @notice function to set the price of subscribing
    /// @param numerator the price numerator
    function setPrice(uint256 numerator) external;

    /// @notice function to set the price of subscribing
    /// @return price the cost of one second subscription
    function getPrice() external view returns (uint256 price);
}
