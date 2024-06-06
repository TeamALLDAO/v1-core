// SPDX-Licence-Identifier: UNLICENSED

pragma solidity 0.8.19;

import {EIP712} from "openzeppelin/utils/cryptography/EIP712.sol";
import {SafeCast} from "openzeppelin/utils/math/SafeCast.sol";
import {Strings} from "openzeppelin/utils/Strings.sol";
import {ERC20} from "openzeppelin/token/ERC20/ERC20.sol";
import {Votes} from "openzeppelin/governance/utils/Votes.sol";
import {IDAO_Token} from "./interfaces/IDAO_Token.sol";
import {IEventRegister} from "./interfaces/IEventRegister.sol";

/// @title the governance token used by ALLDAO protocol
/// @author Mfon Stephen
/// @dev this token implements the erc1155 token standard
contract DAO_Token is IDAO_Token, Votes, ERC20 {
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

    constructor(string memory _uri, address _register, address _owner) EIP712("DAO_Token", "1") ERC20(_uri) {
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

    /// @notice Explain to an end user what this does
    /// @dev Explain to a developer any extra details
    /// @param `address` owner
    function owner() external view returns (address) {
        return owner;
    }

    /// @notice function to mint new tokens
    /// @dev can only be called by the owner of the token i.e the owner
    /// @param tokenId the id of the token to mint
    /// @param amount the amount to mint
    /// @param to the address to mint the token to
    /// @param data optional data to pass down to `_afterTokenTransfer`
    function mint(uint256 tokenId, uint256 amount, address to, bytes memory data) external onlyOwner {
        _mint(to, tokenId, amount, data);
    }

    /// @notice function to set the uri for a particular tokenId
    /// @dev the tokenURI is set for individual tokenIds
    /// @param tokenId the id of the token to set the uri
    /// @param tokenURI the new uri to set
    function setURI(uint256 tokenId, string memory tokenURI) external onlyOwner {
        _setURI(tokenId, tokenURI);
    }

    /// @notice function to set the base uri for the collection
    /// @dev if the individual tokenURI is not set then the uri is the baseURI + tokenId + ".json"
    /// @param baseURI the baseURI to set
    function setBaseURI(string memory baseURI) external onlyOwner {
        _setBaseURI(baseURI);
    }

    function setRegister(address _register) external onlyOwner {
        register = _register;
    }

    /// @notice function to get the total supply of the governance
    /// @dev exposes the internal function `_getTotalSupply()`
    /// @return `uint256`
    function getTotalSupply() external view returns (uint256) {
        return _getTotalSupply();
    }

    /// @notice function to get the uri for a tokenId
    /// @dev concatenates the baseURI and the tokenId according to opensea standard
    /// @param tokenId the id of the token
    /// @return `string`
    function uri(uint256 tokenId) public view override(ERC20, IDAO_Token) returns (string memory) {
        string memory tokenURI = _tokenURIs[tokenId];

        // If token URI is not set, concatenate base URI and tokenURI (via abi.encodePacked).
        return bytes(tokenURI).length > 0 ? string(abi.encodePacked(_baseURI, tokenId.toString(), ".json")) : tokenURI;
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
        for (uint256 i; i < ids.length; ++i) {
            if (ids[i] == 0) {
                _transferVotingUnits(from, to, amounts[i]);
                uint256 fromBalance = balanceOf(from, 0);
                uint256 toBalance = balanceOf(to, 0);
                emit VoteUpdate(from, fromBalance, to, toBalance);
                IEventRegister(register).registerVoteUpdate(address(this), from, fromBalance, to, toBalance);
            }
        }
        super._afterTokenTransfer(operator, from, to, ids, amounts, data);
    }

    /// @notice function that tracks the user dao shares
    /// @dev required implementation by `Votes` contract
    /// @param account account to get the voting units
    /// @return `uint256`
    function _getVotingUnits(address account) internal view override returns (uint256) {
        return balanceOf(account, 0);
    }

    function _setURI(uint256 tokenId, string memory tokenURI) internal virtual {
        _tokenURIs[tokenId] = tokenURI;
    }

    /// @dev Sets `baseURI` as the `_baseURI` for all tokens
    function _setBaseURI(string memory baseURI) internal virtual {
        _baseURI = baseURI;
    }
}
