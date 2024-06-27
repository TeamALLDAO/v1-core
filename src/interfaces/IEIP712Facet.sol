// SPDX-License-Identifier: UNLICENCED

pragma solidity 0.8.20;

interface IEIP712Facet {
    struct EIP712Storage {
        bytes32 cachedDomainSeparator;
        uint256 cachedChainId;
        address cachedThis;
        bytes32 hashedName;
        bytes32 hashedVersion;
        ShortString name;
        ShortString version;
        string nameFallback;
        string versionFallback;
    }
}
