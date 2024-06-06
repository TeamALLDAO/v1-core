// SPDX-Licence-Identifier: UNLICENSED

pragma solidity 0.8.19;

import {IERC1155} from "openzeppelin/token/ERC1155/IERC1155.sol";
import {IVotes} from "openzeppelin/governance/utils/IVotes.sol";

/// @title the interface for the DAO_Token
/// @author Mfon Stephen Nwa
/// @dev this interface is just the combination of the IERC1155 and IVotes interfaces
interface IDAO_Token is IERC1155, IVotes {
    /// @notice the event emitted when the token index zero is transfered
    /// @dev it is used to track the daos that a user belongs to
    /// @param sender the address of the person sending
    /// @param senderBalance the new balance of the sender
    /// @param reciever the address of the reciever
    /// @param recieverBalance the new balance of the reciever
    event VoteUpdate(address sender, uint256 senderBalance, address reciever, uint256 recieverBalance);

    /// @notice returns the uri string
    /// @param tokenId the tokenId of the token to view the uri
    /// @return `string` the uri of the token
    function uri(uint256 tokenId) external view returns (string memory);

    function owner() external view returns (address);

    function getTotalSupply() external view returns (uint256);

    function setBaseURI(string memory baseURI) external;

    function setURI(uint256 tokenId, string memory tokenURI) external;

    function setRegister(address _register) external;

    function mint(uint256 tokenId, uint256 amount, address to, bytes memory data) external;
}
