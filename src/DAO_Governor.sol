// SPDX-Licence-Identifier: UNLICENSED

pragma solidity 0.8.20;

/// External Library

import {Address} from "openzeppelin/utils/Address.sol";
import {ERC1155Holder} from "openzeppelin/token/ERC1155/utils/ERC1155Holder.sol";
import {ERC721Holder} from "openzeppelin/token/ERC721/utils/ERC721Holder.sol";
import {DoubleEndedQueue} from "openzeppelin/utils/structs/DoubleEndedQueue.sol";

/// Interfaces

import {IDiamondCut} from "./interfaces/IDiamondCut.sol";
import {IDiamondLoupe} from "./interfaces/IDiamondLoupe.sol";
import {IDAO_Governor, IListing, IPayment} from "./interfaces/IDAO_Governor.sol";
import {IDAO_Token} from "./interfaces/IDAO_Token.sol";
import {IEventRegister} from "./interfaces/IEventRegister.sol";

import {DAO_Token} from "./DAO_Token.sol";

/// Libraries

import {LibDiamond, IDiamond} from "./libraries/LibDiamond.sol";
import {LibGovernance, LibProposal} from "./libraries/LibGovernance.sol";

/// @title DAO Governor Contract
/// @author Mfon Stephen Nwa
/// @notice The DAO contract implementation
contract DAO_Governor is IDAO_Governor, ERC1155Holder, ERC721Holder {
    using DoubleEndedQueue for DoubleEndedQueue.Bytes32Deque;

    error ProposalIdExists(uint256);
    error NotAMember(address);
    error VotingNotStarted(uint256 proposalId);
    error InvalidProposal(uint256 proposalId);
    error InvalidState();
    error NotTheProposer(address caller, uint256 proposalId);
    error NoVotingRights(address caller, uint256 proposalId);
    error FunctionNotFound(bytes4 _functionSelector);
    error CannotCancel_VotingStarted(uint256 proposalId);
    error OnlyGovernance();

    modifier onlyGovernance() {
        LibGovernance.GovernanceStorage storage govStorage = LibGovernance.governanceStorage();
        DoubleEndedQueue.Bytes32Deque memory govCall = govStorage.governanceCall;
        if (msg.sender != address(this)) revert OnlyGovernance();
        bytes32 msgDataHash = keccak256(msg.data);
        // loop until popping the expected operation - throw if deque is empty (operation not authorized)
        while (govCall.popFront() != msgDataHash) {}
        _;
    }

    constructor(string memory _uri, LibGovernance.Deployment[] memory deployments, address _register) {
        // LibGovernance.addDeployment();
        // bytes memory data = abi.encodeWithSignature(signatureString, arg);
        // LibDiamond.initializeDiamondCut(init, data);
        LibDiamond.setContractOwner(address(this));
        LibGovernance.setURI(_uri);
        LibGovernance.setRegister(_register);
        // deploy the token
    }

    /// Public and External Functions

    function uri() external view returns (string memory) {
        return LibGovernance.uri();
    }

    function isMember(address user) external view returns (bool) {
        IDAO_Token token = IDAO_Token(LibGovernance.token());
        return token.balanceOf(user, 0) > 0;
    }

    /// @notice gets the user shares in percent
    /// @dev shares is (token total supply / user balance) * 100
    /// @param user the user to get the shares
    /// @return `uint8` the user shares
    function getShares(address user) external view returns (uint256) {
        IDAO_Token token = IDAO_Token(LibGovernance.token());
        uint256 totalSupply = token.getTotalSupply();
        uint256 owned = token.balanceOf(user, 0);
        if (owned == 0) return 0;
        return (totalSupply / owned) * 100;
    }

    function getProposal(uint256 proposalId) external view returns (LibProposal.Proposal memory proposal) {
        proposal = LibProposal.getProposal(proposalId);
    }

    function getDeployment(string memory name) internal view returns (address deploymentAddress) {}

    function proposeListing(string memory _descriptionURI, IListing.ListingRequest memory listingRequest) external {
        address listingContract = LibGovernance.getDeployment("Listing");
        bytes memory data = abi.encodeWithSignature("createListing(ListingRequest)", listingRequest);
        LibProposal.Call memory call = LibProposal.Call({targetAddress: listingContract, targetCalldata: data});
        _propose(msg.sender, _descriptionURI, call);
    }

    function proposeListings(string memory _descriptionURI, IListing.ListingRequest[] memory listingRequests)
        external
    {
        address listingContract = LibGovernance.getDeployment("Listing");
        bytes memory data = abi.encodeWithSignature("createListings(ListingRequest[])", listingRequests);
        LibProposal.Call memory call = LibProposal.Call({targetAddress: listingContract, targetCalldata: data});
        _propose(msg.sender, _descriptionURI, call);
    }

    function proposePayment(string memory _descriptionURI, IPayment.PaymentRequest memory paymentRequest) external {
        address paymentContract = LibGovernance.getDeployment("Payment");
        bytes memory data = abi.encodeWithSignature("createPayment(PaymentRequest)", paymentRequest);
        LibProposal.Call memory call = LibProposal.Call({targetAddress: paymentContract, targetCalldata: data});
        _propose(msg.sender, _descriptionURI, call);
    }

    function proposePayments(string memory _descriptionURI, IPayment.PaymentRequest[] memory paymentRequests)
        external
    {
        address paymentContract = LibGovernance.getDeployment("Payment");
        bytes memory data = abi.encodeWithSignature("createPayments(PaymentRequest[])", paymentRequests);
        LibProposal.Call memory call = LibProposal.Call({targetAddress: paymentContract, targetCalldata: data});
        _propose(msg.sender, _descriptionURI, call);
    }

    function propose(string memory _descriptionURI, LibProposal.Call memory _call) external returns (uint256) {
        _propose(msg.sender, _descriptionURI, _call);
    }

    function cancelProposal(uint256 proposalId) external {
        LibProposal.Proposal storage proposal = LibProposal.getProposal(proposalId);
        if (proposal.proposer != msg.sender) revert NotTheProposer(msg.sender, proposalId);
        if (proposal.proposalStatus != LibProposal.ProposalStatus.Delay) revert CannotCancel_VotingStarted(proposalId);
        proposal.proposalStatus = LibProposal.ProposalStatus.Cancelled;
    }

    function castVote(uint256 proposalId, LibProposal.Vote vote) external {
        _castVote(msg.sender, proposalId, vote);
    }

    function voteReciept(uint256 proposalId) external returns (LibProposal.Vote vote) {
        vote = LibProposal.viewVote(msg.sender, proposalId);
    }

    function execute(uint256 proposalId) external {
        //     function execute(
        //     address[] memory targets,
        //     uint256[] memory values,
        //     bytes[] memory calldatas,
        //     bytes32 descriptionHash
        // ) public payable virtual override returns (uint256) {
        //     uint256 proposalId = hashProposal(targets, values, calldatas, descriptionHash);

        //     ProposalState currentState = state(proposalId);
        //     require(
        //         currentState == ProposalState.Succeeded || currentState == ProposalState.Queued,
        //         "Governor: proposal not successful"
        //     );
        //     _proposals[proposalId].executed = true;

        //     emit ProposalExecuted(proposalId);

        //     _beforeExecute(proposalId, targets, values, calldatas, descriptionHash);
        //     _execute(proposalId, targets, values, calldatas, descriptionHash);
        //     _afterExecute(proposalId, targets, values, calldatas, descriptionHash);

        //     return proposalId;
        // }
    }

    /// Private and Internal Functions

    function updateProposal(uint256 proposalId) internal {}

    function _castVote(address user, uint256 proposalId, LibProposal.Vote vote) private {
        LibProposal.Proposal storage proposal = LibProposal.getProposal(proposalId);
        uint256 voteStartTimestamp = proposal.voteStartTimestamp;
        uint256 voteEndTimestamp = proposal.voteEndTimestamp;
        address token = LibGovernance.token();
        LibProposal.ProposalStatus status = proposal.proposalStatus;

        if (voteStartTimestamp <= 0) revert InvalidProposal(proposalId);
        if (status != LibProposal.ProposalStatus.Active || status != LibProposal.ProposalStatus.Delay) {
            revert InvalidState();
        }
        if (block.timestamp < voteStartTimestamp) revert VotingNotStarted(proposalId);
        if (block.timestamp > voteEndTimestamp) {
            updateProposal(proposalId);
            return;
        }

        uint256 userVotingRight = IDAO_Token(token).getPastVotes(msg.sender, voteStartTimestamp);
        if (userVotingRight <= 0) revert NoVotingRights(msg.sender, proposalId);

        proposal.proposalStatus = LibProposal.ProposalStatus.Active;
        LibProposal.castVote(proposalId, user, vote, userVotingRight);
    }

    function _hashProposal(string memory description, LibProposal.Call memory calls)
        private
        pure
        returns (uint256 proposalId)
    {
        proposalId = uint256(keccak256(abi.encode(description, calls)));
    }

    function _propose(address proposer, string memory _descriptionURI, LibProposal.Call memory _call)
        private
        returns (uint256)
    {
        uint256 id = _hashProposal(_descriptionURI, _call);
        LibGovernance.ensureIsProposer(msg.sender);
        LibGovernance.GovernanceStorage storage govStorage = LibGovernance.governanceStorage();
        LibGovernance.GovernanceSetting memory govSetting = govStorage.governorSetting;

        uint256 votingDelay = govSetting.votingDelay;
        uint256 votingPeriod = govSetting.votingPeriod;
        uint256 executionDelay = govSetting.executionDelay;

        LibProposal.Proposal memory proposal = LibProposal.Proposal({
            proposalId: id,
            forVotes: 0,
            againstVotes: 0,
            proposalCreationTimestamp: block.timestamp,
            voteStartTimestamp: votingDelay + block.timestamp,
            voteEndTimestamp: votingPeriod + votingDelay + block.timestamp,
            executionTimestamp: executionDelay + votingPeriod + votingDelay + block.timestamp,
            proposalStatus: LibProposal.ProposalStatus.Delay,
            proposer: proposer,
            descriptionURI: _descriptionURI,
            calls: _call
        });
        LibProposal.setProposal(id, proposal);
        IEventRegister(govStorage.register).registerProposal(
            address(this), proposer, _descriptionURI, _call, block.timestamp
        );
    }

    /// Governance Functions

    function relay(address target, uint256 value, bytes calldata data) external payable onlyGovernance {
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        Address.verifyCallResult(success, returndata, "Governor: relay reverted without message");
    }

    function setURI(string memory URI) external onlyGovernance {
        LibGovernance.setURI(URI);
    }

    function setRegister(address register) external onlyGovernance {
        LibGovernance.setRegister(register);
        IDAO_Token token = IDAO_Token(LibGovernance.token());
        token.setRegister(register);
    }

    function addDeployment() external onlyGovernance {}

    function addFunctions(address facetAddress, bytes4[] memory functionSelectors) external onlyGovernance {}

    function removeFunctions(address facetAddress, bytes4[] memory functionSelectors) external onlyGovernance {}

    function replaceFunctions(address facetAddress, bytes4[] memory functionSelectors) external onlyGovernance {}

    /// @notice fallback function
    /// @dev Find facet for function that is called and execute the
    /// @dev function if a facet is found and return any value.
    fallback() external payable {
        LibDiamond.DiamondStorage storage ds;
        bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
        // get diamond storage
        assembly {
            ds.slot := position
        }
        // get facet from function selector
        address facet = ds.facetAddressAndSelectorPosition[msg.sig].facetAddress;
        if (facet == address(0)) {
            revert FunctionNotFound(msg.sig);
        }
        // Execute external function from facet using delegatecall and return any value.
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the facet
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    receive() external payable {}
}
