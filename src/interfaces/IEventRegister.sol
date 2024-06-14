// SPDX-Licence-Identifier: UNLICENSED

pragma solidity 0.8.20;

import {LibProposal} from "../libraries/LibProposal.sol";

interface IEventRegister {
    event ProposalExecuted();

    event Proposed();

    event ProposalCancelled();

    function registerCreateDao() external;

    function registerUpdatedGovernanceURI(address dao, string memory newURI) external;

    function registerProposal(address dao, LibProposal.Proposal memory proposal) external;

    function registerProposalState(address dao, LibProposal.ProposalStatus proposalState) external;

    function registerAddFunction(bytes4[] memory selector, address facet) external;

    function registerRemoveFunction(bytes4[] memory selector, address facet) external;

    function registerReplaceFunction(bytes4[] memory selector, address facet) external;

    function registerMemberUpdate() external;

    function regisgterPayment() external;

    function registerPaymentUpdate() external;
}
