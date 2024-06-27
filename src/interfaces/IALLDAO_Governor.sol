// SPDX-Licence-Identifier: UNLICENSED

pragma solidity 0.8.20;

import "./IDAO_Governor.sol";
import "./IEventRegister.sol";

interface IALLDAO_Governor is IDAO_Governor {
    struct Shares {
        address user;
        uint256 percent;
    }

    event DAO_Created(uint256 id, address DAO, string DAO_Name);

    function createDAO(string memory daoName, Shares[] memory shares) external;

    function isChildDao(address) external view returns (bool);
}
