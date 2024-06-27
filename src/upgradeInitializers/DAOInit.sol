// SPDX-Licence-Identifier: UNLICENSED

import {IDiamond} from "../interfaces/IDiamond.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";
import {IEIP712Facet} from "../interfaces/IEIP712Facet.sol";
import {LibGovernance} from "../libraries/LibGovernance.sol";
import {DAO_Token} from "../DAO_Token.sol";
import {ShortStrings, ShortString} from "openzeppelin/utils/ShortStrings.sol";

pragma solidity 0.8.19;

contract DAOInit {
    bytes32 private constant TYPE_HASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    function init(string memory name, string memory symbol, string memory version, address register, address payment)
        external
    {
        DAO_Token token = DAO_Token(register, msg.sender, name, symbol);
        address[] memory addresses = [address(token), payment, register];
        string[] memory names = ["token", "payment", "register"];
        LibGovernance.addDeployment(addresses, names);

        IEIP712Facet.EIP712Storage storage es;
        bytes32 position = keccak256("diamond.standard.eip712.storage");
        assembly {
            es.slot := position
        }
        es.name = name.toShortStringWithFallback(es.nameFallback);
        es.version = version.toShortStringWithFallback(es.versionFallback);
        es.hashedName = keccak256(bytes(name));
        es.hashedVersion = keccak256(bytes(version));

        es.cachedChainId = block.chainid;
        es.cachedDomainSeparator =
            keccak256(abi.encode(TYPE_HASH, es.hashedName, es.hashedVersion, block.chainid, address(this)));
        es.cachedThis = address(this);
    }
}
