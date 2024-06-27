// SPDX-License-Identifier: UNLICENCED

pragma solidity 0.8.20;

import {IALLDAO_Governor} from "../interfaces/IALLDAO_Governor.sol";
import {DAO_GovernorFacet} from "./DAOFacet.sol";

contract ALLDAO_GovernorFacet is DAO_GovernorFacet, IALLDAO_Governor {
    function createDAO(string memory daoName, Shares[] memory shares) external virtual {}

    function isChildDao(address) external view virtual returns (bool) {}

    function getDao(address) external view virtual returns (bool) {}
}
