// SPDX-Licence-Identifier: UNLICENSED

pragma solidity 0.8.19;

/// @title the interface that the `Profile` contract implements
/// @author Mfon Stephen Nwa
interface IProfile {
    /// @notice Ethe event emitted when a user profile is updated
    /// @param user the user address
    /// @param DAO the dao the user refrences
    /// @param newProfileURI the new profile uri the user wants to set
    event ProfileUpdated(address user, address DAO, string newProfileURI);

    /// @notice the event emitted when a new DAO is added
    /// @param DAO the dao address added
    /// @param name the name of the dao
    event DAOAdded(address DAO, string name);

    /// @notice the function to update user profile URI
    /// @dev can only be called by a DAO under ALLDAO
    /// @param user the user address
    /// @param dao the dao address the user is refrencing
    /// @param URI the new user URI
    function updateProfile(address user, address dao, string memory URI) external;

    /// @notice function to get a user profile URI
    /// @param user the address of the user
    function getProfile(address user) external view returns (string memory);

    /// @notice the function to add a dao to the daoRegistry
    /// @dev can only be called by ALLDAO
    /// @param dao the address of the dao
    /// @param name the name of the dao
    function addDAO(address dao, string memory name) external;

    /// @notice function to view the dao address linked to a name
    /// @param daoName the name of the dao to get
    function getDAO(string memory daoName) external view returns (address);
}
