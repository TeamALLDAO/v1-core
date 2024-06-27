// SPDX-Licence-Identifier: UNLICENSED

pragma solidity 0.8.20;

/// External Library

import {Address} from "openzeppelin/utils/Address.sol";
import {ERC1155Holder} from "openzeppelin/token/ERC1155/utils/ERC1155Holder.sol";
import {ERC721Holder} from "openzeppelin/token/ERC721/utils/ERC721Holder.sol";
import {DoubleEndedQueue} from "openzeppelin/utils/structs/DoubleEndedQueue.sol";
// import {EIP712} from "openzeppelin/utils/cryptography/EIP712.sol";
import {ECDSA} from "openzeppelin/utils/cryptography/ECDSA.sol";
import {IERC165, ERC165} from "openzeppelin/utils/introspection/ERC165.sol";

/// Interfaces

import {IPayment} from "../interfaces/IPayment.sol";
import {IDiamondCut} from "../interfaces/IDiamondCut.sol";
import {IDiamondLoupe} from "../interfaces/IDiamondLoupe.sol";
import {IDAO_Governor, IListing, IPayment} from "../interfaces/IDAO_Governor.sol";
import {IDAO_Token} from "../interfaces/IDAO_Token.sol";
import {IEventRegister} from "../interfaces/IEventRegister.sol";
import {EIP712Facet} from "./EIP712Facet.sol";

import {DAO_Token} from "../DAO_Token.sol";

/// Libraries

import {LibDiamond, IDiamond} from "../libraries/LibDiamond.sol";
import {LibGovernance, LibProposal} from "../libraries/LibGovernance.sol";
import {LibNonce} from "../libraries/LibNonce.sol";

/// @title DAO Governor Contract
/// @author Mfon Stephen Nwa
/// @notice The DAO contract implementation
contract DAO_GovernorFacet is ERC165, EIP712Facet, IDAO_Governor, ERC1155Holder, ERC721Holder {
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
    error ExpiredSignature(uint256 deadline);
    error InvalidSigner(address signer, address proposer);
    error OnlyGovernance();

    uint256 constant MAXQUORUM = 1e18;
    uint256 constant MINQUORUM = 0.5e18;
    bytes32 private constant PROPOSE_PAYMENT_TYPEHASH = keccak256(
        "ProposePayment(address proposer,string descriptionURI,PaymentRequest paymentRequest,uint256 nonce,uint256 deadline)"
    );
    bytes32 private constant PROPOSE_PAYMENTS_TYPEHASH = keccak256(
        "ProposePayments(address proposer,string descriptionURI,PaymentRequest[] paymentRequests,uint256 nonce,uint256 deadline)"
    );
    bytes32 private constant PROPOSE_TYPEHASH =
        keccak256("Propose(address proposer,string descriptionURI,Call call,uint256 nonce,uint256 deadline)");
    bytes32 private constant CANCEL_PROPOSAL_TYPEHASH =
        keccak256("CancelProposal(address proposer,uint256 proposalId,uint256 nonce,uint256 deadline)");
    bytes32 private constant CAST_VOTE_TYPEHASH =
        keccak256("CastVote(address voter,uint256 proposalId,Vote vote,uint256 nonce,uint256 deadline)");
    bytes32 private constant EXECUTE_TYPEHASH =
        keccak256("Execute(address executor,uint256 proposalId,uint256 nonce,uint256 deadline)");

    modifier onlyGovernance() {
        LibGovernance.GovernanceStorage storage govStorage = LibGovernance.governanceStorage();
        DoubleEndedQueue.Bytes32Deque storage govCall = govStorage.governanceCall;
        if (msg.sender != address(this)) revert OnlyGovernance();
        bytes32 msgDataHash = keccak256(msg.data);
        // loop until popping the expected operation - throw if deque is empty (operation not authorized)
        while (govCall.popFront() != msgDataHash) {}
        _;
    }

    /// Public Functions

    function supportsInterface(bytes4 interfaceId) public view override(ERC165, ERC1155Holder) returns (bool) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.supportedInterfaces[interfaceId];
    }

    function hashProposal(address target, uint256 value, bytes memory call_data, string memory descriptionURI)
        public
        pure
        returns (uint256)
    {
        return uint256(keccak256(abi.encode(target, value, call_data, descriptionURI)));
    }

    function quorum() public view virtual returns (uint256) {
        LibGovernance.GovernanceStorage storage govStorage = LibGovernance.governanceStorage();
        return govStorage.governorSetting.quorumFraction;
    }

    // External Functions

    function uri() external view returns (string memory) {
        return LibGovernance.uri();
    }

    function isMember(address user) external view returns (bool) {
        IDAO_Token token = IDAO_Token(LibGovernance.token());
        return token.getVotes(user) > 0;
    }

    function getSharesPercent(address user) external view returns (uint256) {
        IDAO_Token token = IDAO_Token(LibGovernance.token());
        uint256 totalSupply = token.totalSupply();
        uint256 owned = token.getVotes(user);
        if (owned == 0) return 0;
        return totalSupply * 100 / owned;
    }

    function getProposal(uint256 proposalId) external view returns (LibProposal.Proposal memory proposal) {
        proposal = LibProposal.getProposal(proposalId);
    }

    function getDeployment(string memory name) external view returns (address deploymentAddress) {
        return LibGovernance.getDeployment(name);
    }

    function getNonce(address owner) external view returns (uint256) {
        return LibNonce.nonces(owner);
    }

    function proposePayment(string memory _descriptionURI, IPayment.PaymentRequest memory paymentRequest) external {
        address paymentContract = LibGovernance.getDeployment("payment");
        bytes memory data = abi.encodeWithSelector(IPayment.createPayment.selector, paymentRequest);
        LibProposal.Call memory call = LibProposal.Call({targetAddress: paymentContract, targetCalldata: data});
        _propose(msg.sender, _descriptionURI, call);
    }

    function proposePaymentBySig(
        address proposer,
        string memory descriptionURI,
        IPayment.PaymentRequest memory paymentRequest,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        bytes32 structHash = keccak256(
            abi.encode(
                PROPOSE_PAYMENT_TYPEHASH,
                proposer,
                descriptionURI,
                paymentRequest,
                LibNonce.useNonce(proposer),
                deadline
            )
        );
        _verify_struct_hash(deadline, proposer, structHash, v, r, s);

        address paymentContract = LibGovernance.getDeployment("payment");
        bytes memory data = abi.encodeWithSelector(IPayment.createPayment.selector, paymentRequest);
        LibProposal.Call memory call = LibProposal.Call({targetAddress: paymentContract, targetCalldata: data});
        _propose(proposer, descriptionURI, call);
    }

    function proposePayments(string memory _descriptionURI, IPayment.PaymentRequest[] memory paymentRequests)
        external
    {
        address paymentContract = LibGovernance.getDeployment("payment");
        bytes memory data = abi.encodeWithSelector(IPayment.createPayments.selector, paymentRequests);
        LibProposal.Call memory call = LibProposal.Call({targetAddress: paymentContract, targetCalldata: data});
        _propose(msg.sender, _descriptionURI, call);
    }

    function proposePaymentsBySig(
        address proposer,
        string memory descriptionURI,
        IPayment.PaymentRequest[] memory paymentRequests,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        bytes32 structHash = keccak256(
            abi.encode(
                PROPOSE_PAYMENT_TYPEHASH,
                proposer,
                descriptionURI,
                paymentRequests,
                LibNonce.useNonce(proposer),
                deadline
            )
        );
        _verify_struct_hash(deadline, proposer, structHash, v, r, s);
        address paymentContract = LibGovernance.getDeployment("payment");
        bytes memory data = abi.encodeWithSelector(IPayment.createPayments.selector, paymentRequests);
        LibProposal.Call memory call = LibProposal.Call({targetAddress: paymentContract, targetCalldata: data});
        _propose(proposer, descriptionURI, call);
    }

    function propose(string memory descriptionURI, LibProposal.Call memory _call) external returns (uint256) {
        _propose(msg.sender, descriptionURI, _call);
    }

    function proposeBySig(
        address proposer,
        string memory descriptionURI,
        LibProposal.Call memory call,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256) {
        bytes32 structHash = keccak256(
            abi.encode(PROPOSE_PAYMENT_TYPEHASH, proposer, descriptionURI, call, LibNonce.useNonce(proposer), deadline)
        );

        _verify_struct_hash(deadline, proposer, structHash, v, r, s);
        _propose(proposer, descriptionURI, call);
    }

    function cancelProposal(uint256 proposalId) external {
        LibProposal.Proposal storage proposal = LibProposal.getProposal(proposalId);
        if (proposal.proposer != msg.sender) revert NotTheProposer(msg.sender, proposalId);
        if (proposal.proposalStatus != LibProposal.ProposalStatus.Delay) revert CannotCancel_VotingStarted(proposalId);
        proposal.proposalStatus = LibProposal.ProposalStatus.Cancelled;
    }

    function cancelProposalBySig(address proposer, uint256 proposalId, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external
    {
        bytes32 structHash =
            keccak256(abi.encode(CANCEL_PROPOSAL_TYPEHASH, proposer, proposalId, LibNonce.useNonce(proposer), deadline));

        _verify_struct_hash(deadline, proposer, structHash, v, r, s);

        LibProposal.Proposal storage proposal = LibProposal.getProposal(proposalId);
        if (proposal.proposer != proposer) revert NotTheProposer(proposer, proposalId);
        if (proposal.proposalStatus != LibProposal.ProposalStatus.Delay) revert CannotCancel_VotingStarted(proposalId);
        proposal.proposalStatus = LibProposal.ProposalStatus.Cancelled;
    }

    function castVote(uint256 proposalId, LibProposal.Vote vote) external {
        _castVote(msg.sender, proposalId, vote);
    }

    function castVoteBySig(
        address voter,
        uint256 proposalId,
        LibProposal.Vote vote,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        bytes32 structHash =
            keccak256(abi.encode(CAST_VOTE_TYPEHASH, voter, proposalId, vote, LibNonce.useNonce(voter), deadline));
        _verify_struct_hash(deadline, voter, structHash, v, r, s);
        _castVote(voter, proposalId, vote);
    }

    function voteReciept(uint256 proposalId) external view returns (LibProposal.Vote vote) {
        vote = LibProposal.viewVote(msg.sender, proposalId);
    }

    function execute(uint256 proposalId) external {
        _execute(msg.sender, proposalId);
    }

    function executeBySig(address executor, uint256 proposalId, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external
    {
        bytes32 structHash =
            keccak256(abi.encode(EXECUTE_TYPEHASH, executor, proposalId, LibNonce.useNonce(executor), deadline));

        _verify_struct_hash(deadline, executor, structHash, v, r, s);
        _execute(executor, proposalId);
    }

    /// Core Governance Functions

    function relay(address target, uint256 value, bytes calldata data) external payable onlyGovernance {
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        Address.verifyCallResult(success, returndata, "Governor: relay reverted without message");
    }

    function setQuorumFraction(uint256 quorumFraction) external onlyGovernance {
        if (quorumFraction >= MAXQUORUM || quorumFraction <= MINQUORUM) {
            revert;
        }
        LibGovernance.GovernanceStorage storage govStorage = LibGovernance.governanceStorage();
        govStorage.governorSetting.quorumFraction = quorumFraction;
    }

    function setURI(string memory URI) external onlyGovernance {
        LibGovernance.setURI(URI);
    }

    function setRegister(address register) external onlyGovernance {
        LibGovernance.setRegister(register);
        IDAO_Token token = IDAO_Token(LibGovernance.token());
        token.setRegister(register);
    }

    function addFunctions(address facetAddress, bytes4[] memory functionSelectors) external onlyGovernance {
        LibDiamond.addFunctions(facetAddress, functionSelectors);
    }

    function removeFunctions(address facetAddress, bytes4[] memory functionSelectors) external onlyGovernance {
        LibDiamond.removeFunctions(facetAddress, functionSelectors);
    }

    function replaceFunctions(address facetAddress, bytes4[] memory functionSelectors) external onlyGovernance {
        LibDiamond.replaceFunctions(facetAddress, functionSelectors);
    }

    // Private Functions

    function _castVote(address voter, uint256 proposalId, LibProposal.Vote vote) private {
        LibProposal.Proposal storage proposal = LibProposal.getProposal(proposalId);
        uint256 voteStartTimestamp = proposal.voteStartTimestamp;
        uint256 voteEndTimestamp = proposal.voteEndTimestamp;
        address token = LibGovernance.token();
        LibProposal.ProposalStatus status = proposal.proposalStatus;

        if (voteStartTimestamp <= 0) revert InvalidProposal(proposalId);
        if (status != LibProposal.ProposalStatus.Active || status != LibProposal.ProposalStatus.Delay) {
            revert InvalidState();
        }

        proposal.proposalStatus = LibProposal.ProposalStatus.Active;
        if (block.timestamp < voteStartTimestamp) revert VotingNotStarted(proposalId);
        if (block.timestamp >= voteEndTimestamp) {
            LibProposal.updateState(proposalId);
            return;
        }

        uint256 userVotingRight = IDAO_Token(token).getPastVotes(msg.sender, voteStartTimestamp);
        if (userVotingRight <= 0) revert NoVotingRights(msg.sender, proposalId);

        proposal.proposalStatus = LibProposal.ProposalStatus.Active;
        LibProposal.castVote(proposalId, voter, vote, userVotingRight);
    }

    function _propose(address proposer, string memory _descriptionURI, LibProposal.Call memory _call)
        private
        returns (uint256)
    {
        LibGovernance.ensureIsProposer(msg.sender);
        LibGovernance.GovernanceStorage storage govStorage = LibGovernance.governanceStorage();
        LibGovernance.GovernanceSetting memory govSetting = govStorage.governorSetting;

        uint256 proposalId_new = hashProposal(_call.targetAddress, _call.value, _call.targetCalldata, _descriptionURI);
        LibProposal.Proposals storage ps = LibProposal.proposalStorage();

        if (ps.proposals[proposalId_new].proposalStatus != LibProposal.ProposalStatus.None) {
            revert ProposalIdExists(proposalId_new);
        }
        uint256 votingDelay = govSetting.votingDelay;
        uint256 votingPeriod = govSetting.votingPeriod;
        uint256 executionDelay = govSetting.executionDelay;

        LibProposal.Proposal memory proposal = LibProposal.Proposal({
            proposalId: proposalId_new,
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
        LibProposal.propose(proposal);
        IEventRegister(govStorage.register).registerProposal(
            address(this), proposer, _descriptionURI, _call, block.timestamp
        );
    }

    function _execute(address executor, uint256 proposalId) private {
        LibGovernance.ensureIsProposer(executor);
        LibProposal.Proposal storage proposal = LibProposal.getProposal(proposalId);

        if (proposal.proposalStatus != LibProposal.ProposalStatus.PendingExecution) {
            revert;
        }
        address target = proposal.callStruct.targetAddress;
        uint256 targetvalue = proposal.callStruct.value;
        bytes memory targetData = proposal.callStruct;

        LibGovernance.GovernanceStorage storage gs = LibGovernance.governanceStorage();
        if (target == address(this)) {
            gs.governanceCall.pushBack(keccak256(targetData));
        } else if (!gs.governanceCall.empty()) {
            gs.governanceCall.clear();
        }

        (bool success, bytes memory result) = target.call{value: targetvalue}(targetData);
        if (!success) {
            revert;
        }
        proposal.proposalStatus = LibProposal.ProposalStatus.Executed;
    }

    function _verify_struct_hash(uint256 deadline, address proposer, bytes32 structHash, uint8 v, bytes32 r, bytes32 s)
        private
    {
        if (block.timestamp > deadline) {
            revert ExpiredSignature(deadline);
        }
        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = ECDSA.recover(hash, v, r, s);
        if (signer != proposer) {
            revert InvalidSigner(signer, proposer);
        }
    }
}
