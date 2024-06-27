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

    struct DiamondArgs {
        address owner;
        address init;
        bytes initCalldata;
    }

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
        GovernanceSetting governorSetting;
        mapping(string => address) deployments;
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

    function addDeployment(address[] memory addresses, string[] memory names) internal {
        GovernanceStorage storage gs = governanceStorage();
        if (addresses.length != names.length) {
            revert;
        }

        for (uint256 i; i < names.length; ++i) {
            address tempAddress = gs.deployments[names[i]];
            if (tempAddress != address(0)) revert DeploymentExists(tempAddress);
            gs.deployments[names[i]] = addresses[i];
        }
    }

    function getDeployment(string memory name) internal view returns (address deploymentAddress) {
        GovernanceStorage storage gs = governanceStorage();
        deploymentAddress = gs.deployments[name];
        if (deploymentAddress == address(0)) revert DeploymentDoesNotExist(name);
    }

    function deleteDeployment(string memory name) internal {
        GovernanceStorage storage gs = governanceStorage();
        address deploymentAddress = gs.deployments[name];
        if (deploymentAddress == address(0)) revert DeploymentDoesNotExist(name);
        delete gs.deployments[name];
    }

    function updateDeployment(string memory name, address deployment) internal {
        GovernanceStorage storage gs = governanceStorage();
        address deploymentAddress = gs.deployments[name];
        if (deploymentAddress == address(0)) revert DeploymentDoesNotExist(name);
        gs.deployments[name] = deployment;
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

    function setProposers(address[] memory proposers) internal {
        GovernanceStorage storage gs = governanceStorage();
        gs.proposers = proposers;
    }

    function setExecutors(address[] memory executors) internal {
        GovernanceStorage storage gs = governanceStorage();
        gs.executors = executors;
    }
}
