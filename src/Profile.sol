// SPDX-Licence-Identifier: UNLICENSED

pragma solidity 0.8.19;

import {IProfile} from "./interfaces/IProfile.sol";
import {IALLDAO_Governor} from "./interfaces/IALLDAO_Governor.sol";
import {IDAO_Governor} from "./interfaces/IDAO_Governor.sol";

/// @title the contract that handles user profiles and dao names
/// @author Mfon Stephen Nwa
contract Profile is IProfile {
    mapping(string => address) private daoRecords;
    mapping(address => string) private userProfiles;
    uint8 constant STRING_LIMIT = 32;
    address public immutable owner;

    constructor() {
        owner = msg.sender;
    }

    /// @inheritdoc	IProfile
    function updateProfile(address user, address dao, string memory URI) external {
        require(IALLDAO_Governor(owner).isChildDao(dao), "callable only from a child dao of ALLDAO");
        require(IDAO_Governor(dao).isMember(user), "not a member of the dao");

        userProfiles[user] = URI;
        emit ProfileUpdated(user, dao, URI);
    }

    /// @inheritdoc	IProfile
    function getProfile(address user) external view returns (string memory) {
        return userProfiles[user];
    }

    /// @inheritdoc	IProfile
    function addDAO(address dao, string memory name) external {
        require(msg.sender == owner, "Only owner can call");
        require(bytes(name).length <= STRING_LIMIT, "maximum lenght for name exceeded");
        require(daoRecords[name] == address(0), "dao name already exists");

        daoRecords[name] = dao;
        emit DAOAdded(dao, name);
    }

    /// @inheritdoc	IProfile
    function getDAO(string memory daoName) external view returns (address) {
        return daoRecords[daoName];
    }
}
