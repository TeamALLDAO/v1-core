// SPDX-Licence-Identifier: UNLICENSED

pragma solidity 0.8.20;

import {LibDiamond, IDiamond} from "./libraries/LibDiamond.sol";
import {LibGovernance} from "./libraries/LibGovernance.sol";

/// @title DAO Governor Contract
/// @author Mfon Stephen Nwa
/// @notice The DAO contract implementation
contract DAO_Governor {
    constructor(IDiamondCut.FacetCut[] memory _diamondCut, LibGovernance.DiamondArgs memory _args) payable {
        LibDiamond.setContractOwner(_args.owner);
        LibDiamond.diamondCut(_diamondCut, _args.init, _args.initCalldata);
    }

    /// @notice fallback function
    /// @dev Find facet for function that is called and execute the
    /// @dev function if a facet is found and return any value.
    fallback() external payable {
        LibDiamond.DiamondStorage storage ds;
        bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
        // get diamond storage
        assembly {
            ds.slot := position
        }
        // get facet from function selector
        address facet = ds.facetAddressAndSelectorPosition[msg.sig].facetAddress;
        if (facet == address(0)) {
            revert FunctionNotFound(msg.sig);
        }
        // Execute external function from facet using delegatecall and return any value.
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the facet
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    receive() external payable {}
}
