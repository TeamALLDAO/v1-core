// SPDX-Licence-Identifier: UNLICENSED

import {IDiamond} from "../interfaces/IDiamond.sol";
import {DiamondLoupeFacet} from "../facets/DiamondLoupeFacet.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";

pragma solidity 0.8.19;

contract DAOInit {
    address diamondLoupe;

    constructor(address _diamondLoupe) {
        diamondLoupe = _diamondLoupe;
    }

    function init() external {
        IDiamond.FacetCut memory facecut = "";
        LibDiamond.diamondCut(facecut, init, data);
    }
}
