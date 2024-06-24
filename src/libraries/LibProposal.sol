// SPDX-Licence-Identifier: UNLICENSED

pragma solidity ^0.8.20;

library LibProposal {
    bytes32 constant PROPOSAL_STORAGE_POSITION = keccak256("diamond.storage.proposal.storage");

    error ProposalExists(uint256 proposalId);
    error AlreadyVoted(uint256 proposalId, address user);

    enum Vote {
        Abstain,
        For,
        Against
    }

    enum ProposalStatus {
        None,
        Delay,
        Cancelled,
        Active,
        Failed,
        PendingExecution,
        Executed
    }

    struct Call {
        address targetAddress;
        bytes targetCalldata;
        uint256 value;
    }

    struct Proposal {
        uint256 proposalId;
        uint256 forVotes;
        uint256 againstVotes;
        uint96 proposalCreationTimestamp;
        uint96 voteStartTimestamp;
        uint96 voteEndTimestamp;
        uint96 executionTimestamp;
        ProposalStatus proposalStatus;
        address proposer;
        string descriptionURI;
        Call callStruct;
    }

    struct Proposals {
        uint256 currentId;
        mapping(uint256 => Proposal) proposals;
        mapping(address => mapping(uint256 => Vote)) votes;
    }

    function proposalStorage() internal pure returns (Proposals storage ps) {
        bytes32 position = PROPOSAL_STORAGE_POSITION;
        assembly {
            ps.slot := position
        }
    }

    function getProposal(uint256 proposalId) internal view returns (Proposal storage) {
        Proposals storage ps = proposalStorage();
        return ps.proposals[proposalId];
    }

    function getCurrentId() internal view returns (uint256) {
        Proposals storage ps = proposalStorage();
        return ps.currentId;
    }

    function getProposalExecutables(uint256 proposalId)
        internal
        view
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {}

    function propose(Proposal memory proposal) internal {
        Proposals storage ps = proposalStorage();
        uint256 proposalId = ps.currentId;
        proposal.proposalId = proposalId;
        if (ps.proposals[proposalId].proposalStatus != ProposalStatus.None) {
            revert ProposalExists(proposalId);
        }
        ps.proposals[proposalId] = proposal;
        ps.currentId += 1;
    }

    function updateProposal(uint256 proposalId) internal {}

    function viewVote(address user, uint256 proposalId) internal view returns (Vote) {
        Proposals storage ps = proposalStorage();
        return ps.votes[user][proposalId];
    }

    function castVote(uint256 proposalId, address user, Vote vote, uint256 votingUnit) internal {
        Proposals storage ps = proposalStorage();
        if (ps.votes[user][proposalId] != Vote.Abstain) revert AlreadyVoted(proposalId, user);
        ps.votes[user][proposalId] = vote;

        if (vote == Vote.For) {
            ps.proposals[proposalId].forVotes += votingUnit;
        } else if (vote == Vote.Against) {
            ps.proposals[proposalId].againstVotes += votingUnit;
        }
    }
}
