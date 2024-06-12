// SPDX-Licence-Identifier: UNLICENSED

pragma solidity 0.8.20;

import {SafeCast} from "openzeppelin/utils/math/SafeCast.sol";
import {Strings} from "openzeppelin/utils/Strings.sol";
import {ERC20Votes} from "openzeppelin/token/ERC20/extensions/ERC20Votes.sol";
import {IDAO_Token} from "./interfaces/IDAO_Token.sol";
import {IEventRegister} from "./interfaces/IEventRegister.sol";

/// @title the governance token used by ALLDAO protocol
/// @author Mfon Stephen
/// @dev this token implements the erc1155 token standard
contract DAO_Token is IDAO_Token, ERC20Votes {
    using Strings for uint256;

    /// @notice the alldao owner address
    address public owner;

    /// @notice the address to register updates
    address public register;

    /// @notice Optional base URI
    string private _baseURI = "";

    /// @notice Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner can call");
        _;
    }

    constructor(address _register, address _owner, string memory _name, string memory _symbol) {
        owner = _owner;
        register = _register;
    }

    // Public Functions

    /// @notice the clock function for tracking voting rights
    /// @dev it is overwritten to use block.timestamp
    /// @return `uint48`
    function clock() public view override returns (uint48) {
        return SafeCast.toUint48(block.timestamp);
    }

    /// @dev Machine-readable description of the clock as specified in EIP-6372.
    function CLOCK_MODE() public view override returns (string memory) {
        // Check that the clock was not modified
        require(clock() == block.timestamp, "Votes: broken clock mode");
        return "mode=blocktimestamp&from=default";
    }

    // External Functions

    /// @notice function to mint new tokens
    /// @dev can only be called by the owner of the token i.e the owner
    /// @param tokenId the id of the token to mint
    /// @param amount the amount to mint
    /// @param to the address to mint the token to
    /// @param data optional data to pass down to `_afterTokenTransfer`
    function mint(uint256 tokenId, uint256 amount, address to, bytes memory data) external onlyOwner {
        _mint(to, amount, data);
    }


    function setRegister(address _register) external onlyOwner {
        register = _register;
    }

    // Internal Functions

    /// @dev hook to log and track tranfers of the governance tokenId
    /// @param operator the operator address
    /// @param from the address that the transfer is from
    /// @param to the reciepient of the tokens
    /// @param ids an array of ids sent
    /// @param amounts an array of the amount of tokens sent
    /// @param data bytes
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override {
        // for (uint256 i; i < ids.length; ++i) {
        //     if (ids[i] == 0) {
        //         _transferVotingUnits(from, to, amounts[i]);
        //         uint256 fromBalance = balanceOf(from, 0);
        //         uint256 toBalance = balanceOf(to, 0);
        //         emit VoteUpdate(from, fromBalance, to, toBalance);
        //         IEventRegister(register).registerVoteUpdate(address(this), from, fromBalance, to, toBalance);
        //     }
        // }
        // super._afterTokenTransfer(operator, from, to, ids, amounts, data);
    }

    /// @notice function that tracks the user dao shares
    /// @dev required implementation by `Votes` contract
    /// @param account account to get the voting units
    /// @return `uint256`
    function _getVotingUnits(address account) internal view override returns (uint256) {
        return balanceOf(account);
    }

}
