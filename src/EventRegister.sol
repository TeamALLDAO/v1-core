// SPDX-Licence-Identifier: UNLICENSED

pragma solidity 0.8.20;

import {IEventRegister, LibProposal} from "./interfaces/IEventRegister.sol";

contract EventRegister is IEventRegister {
    function registerVoteUpdate(
        address dao,
        address sender,
        uint256 senderBalance,
        address reciever,
        uint256 recieverBalance
    ) external {}

    function registerUpdatedGovernanceURI(address dao, string memory newURI) external {}

    function registerProposal(
        address dao,
        address proposer,
        string memory proposalURI,
        LibProposal.Call memory calls,
        uint256 timestampCreated
    ) external {}

    function registerProposalState(uint256 proposalId, uint8 proposalState) external {}

    function registerAddFunction(bytes4[] memory selector, address facet) external {}

    function registerRemoveFunction(bytes4[] memory selector, address facet) external {}

    function registerReplaceFunction(bytes4[] memory selector, address facet) external {}
}
