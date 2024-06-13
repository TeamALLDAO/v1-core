// SPDX-Licence-Identifier: UNLICENSED

pragma solidity 0.8.20;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "openzeppelin/token/ERC20/extensions/IERC20Metadata.sol";
import {IVotes} from "openzeppelin/governance/utils/IVotes.sol"

/// @title the interface for the DAO_Token
/// @author Mfon Stephen Nwa
/// @dev this interface is just the combination of the IERC1155 and IVotes interfaces
interface IDAO_Token is IERC20, IERC20Metadata, IVotes {
    /// @notice the event emitted when the token index zero is transfered
    /// @dev it is used to track the daos that a user belongs to
    /// @param sender the address of the person sending
    /// @param senderBalance the new balance of the sender
    /// @param reciever the address of the reciever
    /// @param recieverBalance the new balance of the reciever
    event VoteUpdate(address sender, uint256 senderBalance, address reciever, uint256 recieverBalance);

    function owner() external view returns (address);

    function getTotalSupply() external view returns (uint256);

    function setRegister(address _register) external;

    function mint(uint256 tokenId, uint256 amount, address to, bytes memory data) external;
}
