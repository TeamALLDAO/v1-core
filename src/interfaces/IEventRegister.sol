// SPDX-Licence-Identifier: UNLICENSED

pragma solidity 0.8.20;

import {LibProposal} from "../libraries/LibProposal.sol";

interface IEventRegister {
    event ProposalExecuted();

    event Proposed();

    event ProposalCancelled();

    function registerMemberCount(address dao, uint256 timestamp, uint256 amount) external;
}
