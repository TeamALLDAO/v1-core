// SPDX-Licence-Identifier: UNLICENSED

pragma solidity 0.8.20;

import {SafeCast} from "openzeppelin/utils/math/SafeCast.sol";
import {Strings} from "openzeppelin/utils/Strings.sol";
import {ERC20Votes, ERC20} from "openzeppelin/token/ERC20/extensions/ERC20Votes.sol";
import {EIP712} from "openzeppelin/utils/cryptography/EIP712.sol";
import {Time} from "openzeppelin/utils/types/Time.sol";

import {IDAO_Token} from "./interfaces/IDAO_Token.sol";
import {IEventRegister} from "./interfaces/IEventRegister.sol";

/// @title the governance token used by ALLDAO protocol
/// @author Mfon Stephen
/// @dev this token implements the erc20 token standard
contract DAO_Token is IDAO_Token, ERC20Votes {
    using Strings for uint256;

    /// @notice total number of token holders
    uint256 public holders;

    /// @notice the alldao owner address
    address public owner;

    /// @notice the address to register updates
    IEventRegister public register;

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner can call");
        _;
    }

    constructor(address _register, address _owner, string memory _name, string memory _symbol)
        ERC20(_name, _symbol)
        EIP712(_name, "1")
    {
        owner = _owner;
        register = IEventRegister(_register);
    }

    function clock() public view override returns (uint48) {
        return Time.timestamp();
    }

    /**
     * @dev Machine-readable description of the clock as specified in EIP-6372.
     */
    // solhint-disable-next-line func-name-mixedcase
    function CLOCK_MODE() public view override returns (string memory) {
        // Check that the clock was not modified
        if (clock() != Time.timestamp()) {
            revert ERC6372InconsistentClock();
        }
        return "mode=timestamp&from=default";
    }
    // External Functions

    /// @notice function to mint new tokens
    /// @dev can only be called by the owner of the token i.e the owner
    /// @param amount the amount to mint
    /// @param to the address to mint the token to
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function setRegister(address _register) external onlyOwner {
        register = IEventRegister(_register);
    }

    function _update(address from, address to, uint256 value) internal override {
        uint256 toBalance = balanceOf(to);
        uint256 beginHolders = holders;

        super._update(from, to, value);

        if (from != address(0) && balanceOf(from) == 0) {
            holders -= 1;
        }

        if (to != address(0) && toBalance == 0) {
            holders += 1;
        }

        if (holders != beginHolders) {
            register.registerMemberCount(address(this), block.timestamp, holders);
        }
    }
}
