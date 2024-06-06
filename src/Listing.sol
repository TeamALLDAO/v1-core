// SPDX-Licence-Identifier: UNLICENSED

pragma solidity 0.8.19;

import {IListing} from "./interfaces/IListing.sol";
import {IDAO_Token} from "./interfaces/IDAO_Token.sol";
import {ERC1155Holder} from "openzeppelin/token/ERC1155/utils/ERC1155Holder.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin/token/ERC20/utils/SafeERC20.sol";

contract Listing is IListing, ERC1155Holder {
    using SafeERC20 for IERC20;

    error Listing__CreatorCannotBeBuyer();
    error Listing__TokenAddressCannotBeZero();
    error Listing__PaymentTokenCannotBeZero();
    error Listing__NumberOfTokensToListCannotBeZero();
    error Listing__PriceOfTokenCannotBeZero();
    error Listing__OnlyCreatorCanCancelListing();
    error Listing__BuyerIsNotAllowedToBuy();
    error Listing__InvalidState();
    error Listing__OnlyOwnerCanCall();

    uint8 public constant DENOMINATOR = 100;
    address public immutable owner;
    uint256 public currentListingId;
    uint8 public feePercent = 3;

    mapping(uint256 => Listing) public listings;

    constructor() {
        owner = msg.sender;
    }

    // Public Functions

    /// @inheritdoc	IListing
    function calculateFee(uint256 amount) public view returns (uint256 feeAmount) {
        feeAmount = (amount * feePercent) / DENOMINATOR;
    }

    /// @inheritdoc	IListing
    function calculateRemovedFee(uint256 amount) public view returns (uint256 feeRemovedAmount) {
        feeRemovedAmount = amount - ((amount * feePercent) / DENOMINATOR);
    }

    // External Functions

    /// @inheritdoc IListing
    function createListing(ListingRequest memory listingRequest) external {
        _createListing(msg.sender, listingRequest);
    }

    /// @inheritdoc IListing
    function createListings(ListingRequest[] memory listingRequests) external {
        for (uint256 i; i < listingRequests.length; ++i) {
            _createListing(msg.sender, listingRequests[i]);
        }
    }

    /// @inheritdoc IListing
    function cancelListing(uint256 listingId) external {
        Listing memory listing = listings[listingId];
        _enforceInState(ListingState.Listed, listing);
        _cancelListing(msg.sender, listing);
    }

    /// @inheritdoc IListing
    function cancelListings(uint256[] memory listingIds) external {
        Listing memory listing;
        for (uint256 i; i < listingIds.length; ++i) {
            listing = listings[listingIds[i]];
            _enforceInState(ListingState.Listed, listing);
            _cancelListing(msg.sender, listing);
        }
    }

    /// @inheritdoc IListing
    function buyListing(uint256 listingId) external {
        Listing memory listing = listings[listingId];
        _enforceInState(ListingState.Listed, listing);
        _buyListing(msg.sender, listing);
    }

    /// @inheritdoc IListing
    function buyListings(uint256[] memory listingIds) external {
        Listing memory listing;
        for (uint256 i; i < listingIds.length; ++i) {
            listing = listings[listingIds[i]];
            _enforceInState(ListingState.Listed, listing);
            _buyListing(msg.sender, listing);
        }
    }

    // Private Functions

    function _createListing(address creator, ListingRequest memory listingRequest) private {
        uint256 id = currentListingId;

        if (listingRequest.buyer == creator) revert Listing__CreatorCannotBeBuyer();
        if (listingRequest.token == address(0)) revert Listing__TokenAddressCannotBeZero();
        if (listingRequest.paymentToken == address(0)) revert Listing__PaymentTokenCannotBeZero();
        if (listingRequest.numberOfTokens <= 0) revert Listing__NumberOfTokensToListCannotBeZero();
        if (listingRequest.price <= 0) revert Listing__PriceOfTokenCannotBeZero();

        Listing memory listing = Listing({
            state: ListingState.Listed,
            listingId: id,
            creator: creator,
            buyer: listingRequest.buyer,
            token: listingRequest.token,
            tokenId: listingRequest.tokenId,
            paymentToken: listingRequest.paymentToken,
            numberOfTokens: listingRequest.numberOfTokens,
            price: listingRequest.price
        });

        listings[id] = listing;
        currentListingId = id + 1;
        IDAO_Token token = IDAO_Token(listing.token);
        token.safeTransferFrom(creator, address(this), listing.tokenId, listing.numberOfTokens, "");
        string memory uri = token.uri(listing.tokenId);
        emit ListingCreated(listing, uri);
    }

    function _cancelListing(address canceller, Listing memory listing) private {
        if (listing.creator != canceller) revert Listing__OnlyCreatorCanCancelListing();

        listing.state = ListingState.Cancelled;
        listings[listing.listingId] = listing;
        IDAO_Token(listing.token).safeTransferFrom(
            address(this), canceller, listing.tokenId, listing.numberOfTokens, ""
        );
        emit ListingCancelled(listing.listingId);
    }

    function _buyListing(address buyer, Listing memory listing) private {
        if (listing.buyer != address(0) || listing.buyer != buyer) revert Listing__BuyerIsNotAllowedToBuy();

        listing.state = ListingState.Sold;
        listings[listing.listingId] = listing;
        IERC20 paymentToken = IERC20(listing.paymentToken);
        paymentToken.safeTransferFrom(buyer, address(this), listing.price);
        paymentToken.safeTransfer(owner, calculateFee(listing.price));
        paymentToken.safeTransfer(listing.creator, calculateRemovedFee(listing.price));
        IDAO_Token(listing.token).safeTransferFrom(address(this), buyer, listing.tokenId, listing.numberOfTokens, "");
        emit ListingSold(listing.listingId);
    }

    function _enforceInState(ListingState listingState, Listing memory listing) private pure {
        if (listing.state != listingState) revert Listing__InvalidState();
    }

    // View Functions

    function getListing(uint256 listingId) external view returns (Listing memory) {
        return listings[listingId];
    }

    function getListings(uint256[] memory listingIds) external view returns (Listing[] memory) {
        Listing[] memory _listings = new Listing[](listingIds.length);
        for (uint256 i; i < listingIds.length; ++i) {
            _listings[i] = listings[listingIds[i]];
        }
        return _listings;
    }

    //// Owner Function

    function setFee(uint8 _feePercent) external {
        if (msg.sender != owner) revert Listing__OnlyOwnerCanCall();
        feePercent = _feePercent;
    }
}
