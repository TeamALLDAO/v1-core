// SPDX-Licence-Identifier: UNLICENSED

pragma solidity 0.8.20;

import {DoubleEndedQueue} from "openzeppelin/utils/structs/DoubleEndedQueue.sol";
import {LibProposal} from "./LibProposal.sol";

error IsNotProposer(address);
error IsNotExecutor(address);
error DeploymentExists(string);
error DeploymentDoesNotExist(string);

/// @title The Library thet helps with handling Governance functions
/// @author Mfon Stephen Nwa
library LibGovernance {
    bytes32 constant GOVERNANCE_STORAGE_POSITION = keccak256("diamond.storage.governance.storage");

    struct Deployment {
        string name;
        address deploymentAddress;
    }

    struct GovernanceSetting {
        uint256 votingPeriod;
        uint256 votingDelay;
        uint256 executionDelay;
        uint256 proposalThreshold;
        uint256 quorumFraction;
    }

    struct GovernanceStorage {
        address[] proposers;
        address[] executors;
        address register;
        GovernanceSetting governorSetting;
        string[] deployments;
        mapping(string => address) deploymentAddresses;
        DoubleEndedQueue.Bytes32Deque governanceCall;
        string uri;
    }

    function governanceStorage() internal pure returns (GovernanceStorage storage gs) {
        bytes32 position = GOVERNANCE_STORAGE_POSITION;
        assembly {
            gs.slot := position
        }
    }

    function setURI(string memory _uri) internal {
        GovernanceStorage storage gs = governanceStorage();
        gs.uri = _uri;
    }

    function uri() internal view returns (string memory _uri) {
        GovernanceStorage storage gs = governanceStorage();
        _uri = gs.uri;
    }

    function token() internal view returns (address tokenAddress) {
        tokenAddress = getDeployment("token");
    }

    function addDeployment(Deployment[] memory deployments) internal {
        GovernanceStorage storage gs = governanceStorage();
        for (uint256 i; i < deployments.length; ++i) {
            if (gs.deploymentAddresses[deployments[i].name] != address(0)) revert DeploymentExists(deployments[i].name);
            gs.deployments.push(deployments[i].name);
            gs.deploymentAddresses[deployments[i].name] = deployments[i].deploymentAddress;
        }
    }

    function getDeployment(string memory name) internal view returns (address deploymentAddress) {
        GovernanceStorage storage gs = governanceStorage();
        deploymentAddress = gs.deploymentAddresses[name];
        if (deploymentAddress == address(0)) revert DeploymentDoesNotExist(name);
    }

    function deleteDeployment(string memory name) internal {
        GovernanceStorage storage gs = governanceStorage();
        address deploymentAddress = gs.deploymentAddresses[name];
        if (deploymentAddress == address(0)) revert DeploymentDoesNotExist(name);
        // todo delete name
        delete gs.deploymentAddresses[name];
    }

    function updateDeployment(string memory name, address deployment) internal {
        GovernanceStorage storage gs = governanceStorage();
        address deploymentAddress = gs.deploymentAddresses[name];
        if (deploymentAddress == address(0)) revert DeploymentDoesNotExist(name);
        gs.deploymentAddresses[name] = deployment;
    }

    function ensureIsProposer(address user) internal view {
        GovernanceStorage storage gs = governanceStorage();
        address[] memory proposers = gs.proposers;
        if (proposers.length == 0) return;
        bool isProposer;
        for (uint256 i; i < proposers.length; ++i) {
            if (user == proposers[i]) {
                isProposer = true;
                break;
            }
        }
        if (!isProposer) revert IsNotProposer(user);
    }

    function ensureIsExecutor(address user) internal view {
        GovernanceStorage storage gs = governanceStorage();
        address[] memory executors = gs.executors;
        if (executors.length == 0) return;
        bool isExecutor;
        for (uint256 i; i < executors.length; ++i) {
            if (user == executors[i]) {
                isExecutor = true;
                break;
            }
        }
        if (!isExecutor) revert IsNotProposer(user);
    }

    function ensureValidShares() internal view {}

    function setProposers(address[] memory proposers) internal {
        GovernanceStorage storage gs = governanceStorage();
        gs.proposers = proposers;
    }

    function setExecutors(address[] memory executors) internal {
        GovernanceStorage storage gs = governanceStorage();
        gs.executors = executors;
    }

    function setRegister(address register) internal {
        GovernanceStorage storage gs = governanceStorage();
        gs.register = register;
    }

    function propose() internal {}

    function cancelProposal() internal {}

    function castVote() internal {}

    function execute() internal {}
}
