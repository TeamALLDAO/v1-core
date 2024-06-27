// SPDX-Licence-Identifier: UNLICENSED

pragma solidity 0.8.20;

import {IListing} from "./IListing.sol";
import {IPayment} from "./IPayment.sol";
import {LibProposal} from "../libraries/LibProposal.sol";

/// @title A title that should describe the contract/interface
/// @author The name of the author
/// @notice Explain to an end user what this does
/// @dev Explain to a developer any extra details
interface IDAO_Governor {
    event Proposed();

    event ProposalCancelled();

    event ProposalExecuted();

    function hashProposal(address target, uint256 value, bytes memory call_data, string memory descriptionURI)
        public
        pure
        returns (uint256);

    function quorum(uint256 timepoint) public view virtual returns (uint256);

    function setQuorumFraction(uint256 quorum) external;

    function uri() external view returns (string memory);

    function isMember(address user) external view returns (bool);

    function getSharesPercent(address user) external view returns (uint256);

    // function proposeListing(string memory _descriptionURI, IListing.ListingRequest memory listingRequest) external;

    // function proposeListings(string memory _descriptionURI, IListing.ListingRequest[] memory listingRequests)
    //     external;

    function proposePayment(string memory _descriptionURI, IPayment.PaymentRequest memory paymentRequest) external;

    function proposePayments(string memory _descriptionURI, IPayment.PaymentRequest[] memory paymentRequests)
        external;

    function propose(string memory _descriptionURI, LibProposal.Call memory _calls) external returns (uint256);

    function getProposal(uint256 proposalId) external view returns (LibProposal.Proposal memory proposal);

    function cancelProposal(uint256 proposalID) external;

    function castVote(uint256 proposalID, LibProposal.Vote vote) external;

    function voteReciept(uint256 proposalId) external returns (LibProposal.Vote vote);

    function execute(uint256 proposalID) external;

    /// The functions below will only be callable after the governance process

    function relay(address target, uint256 value, bytes calldata data) external payable;

    function setURI(string memory URI) external;

    function addFunctions(address facetAddress, bytes4[] memory functionSelectors) external;

    function removeFunctions(address facetAddress, bytes4[] memory functionSelectors) external;

    function replaceFunctions(address facetAddress, bytes4[] memory functionSelectors) external;
}
