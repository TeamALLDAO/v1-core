// SPDX-Licence-Identifier: UNLICENSED

pragma solidity 0.8.20;

import {IALLDAO_Governor} from "./interfaces/IALLDAO_Governor.sol";
import {DAO_Governor} from "./DAO_Governor.sol";

abstract contract ALLDAO_Governor is IALLDAO_Governor, DAO_Governor {
    constructor() {}

    function createDAO(string memory daoName, Shares[] memory shares) external virtual {}

    function isChildDao(address) external view virtual returns (bool) {}

    function getDao(address) external view virtual returns (bool) {}
}
