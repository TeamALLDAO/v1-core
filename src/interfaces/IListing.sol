// SPDX-Licence-Identifier: UNLICENSED

pragma solidity 0.8.19;

import {IERC1155Receiver} from "openzeppelin/token/ERC1155/IERC1155Receiver.sol";

/// @title The Listing Interface the listing contract implements
/// @author Mfon Stephen Nwa
interface IListing is IERC1155Receiver {
    /// @notice the event that is emitted when a listing is created
    /// @param listing the listing struct
    event ListingCreated(Listing listing, string tokenUIR);

    /// @notice the event that is emitted when a listing is cancelled
    /// @param listingId the liting id
    event ListingCancelled(uint256 listingId);

    /// @notice the event that is emitted when a listing is sold
    /// @param listingId the listing id
    event ListingSold(uint256 listingId);

    enum ListingState {
        None,
        Listed,
        Sold,
        Bought,
        Cancelled
    }

    struct ListingRequest {
        address buyer;
        address token;
        uint256 tokenId;
        address paymentToken;
        uint256 numberOfTokens;
        uint256 price;
    }

    struct Listing {
        ListingState state;
        uint256 listingId;
        address creator;
        address buyer;
        address token;
        uint256 tokenId;
        address paymentToken;
        uint256 numberOfTokens;
        uint256 price;
    }

    /// @notice function to create a listing
    /// @dev the buyer parameter in `ListingRequest` can either be the zero address(meaning anybody can buy) or a specific address
    /// @param listingRequest the `ListingRequest` struct
    function createListing(ListingRequest memory listingRequest) external;

    /// @notice function to create multiple listings
    /// @dev the buyer parameter in `ListingRequest` can either be the zero address(meaning anybody can buy) or a specific address
    /// @param listingRequests an array of `ListingRequests`
    function createListings(ListingRequest[] memory listingRequests) external;

    /// @notice function to cancel a listing
    /// @param listingId the listing id
    function cancelListing(uint256 listingId) external;

    /// @notice function to create multiple listings
    /// @param listingIds an array of listing ids
    function cancelListings(uint256[] memory listingIds) external;

    /// @notice function to buy a listing
    /// @dev the caller must either be the buyer or the buyer is the zero address
    /// @param listingId the listing id
    function buyListing(uint256 listingId) external;

    /// @notice function to create multiple listings
    /// @dev the caller must either be the buyer or the buyer is the zero addres
    /// @param listingIds an array of listing ids
    function buyListings(uint256[] memory listingIds) external;

    /// @notice function to calculate the fee deducted from a payment
    /// @param amount the amount to calculate the fee
    /// @return feeAmount the fee
    function calculateFee(uint256 amount) external view returns (uint256 feeAmount);

    /// @notice function to calculate the remaining amount after deducting the fee
    /// @param amount the amount to calculate from
    /// @return feeRemovedAmount the remaining amount after deducting the fee
    function calculateRemovedFee(uint256 amount) external view returns (uint256 feeRemovedAmount);

    /// @notice function to get a listing from storage
    /// @param listingId the listing id
    /// @return `Listing`
    function getListing(uint256 listingId) external view returns (Listing memory);

    /// @notice function to get multiple listings from storage
    /// @param listingIds an array of listing ids
    /// @return `Listing[]`
    function getListings(uint256[] memory listingIds) external view returns (Listing[] memory);

    /// @notice function to set the fee collected
    /// @dev can only be called by the owner
    /// @param _feePercent the fee percent to set
    function setFee(uint8 _feePercent) external;
}
