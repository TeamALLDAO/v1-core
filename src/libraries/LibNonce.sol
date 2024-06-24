// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.20;

library LibNonce {
    bytes32 constant NONCE_STORAGE_POSITION = keccak256("diamond.standard.nonce.storage");

    struct NonceStorage {
        mapping(address account => uint256) nonces;
    }

    function nonceStorage() internal pure returns (NonceStorage storage ns) {
        bytes32 position = NONCE_STORAGE_POSITION;
        assembly {
            ns.slot := position
        }
    }

    /**
     * @dev Returns the next unused nonce for an address.
     */
    function nonces(address owner) internal view virtual returns (uint256) {
        NonceStorage storage ns = nonceStorage();
        return ns.nonces[owner];
    }

    /**
     * @dev Consumes a nonce.
     *
     * Returns the current value and increments nonce.
     */
    function useNonce(address owner) internal virtual returns (uint256) {
        NonceStorage storage ns = nonceStorage();
        unchecked {
            // It is important to do x++ and not ++x here.
            return ns.nonces[owner]++;
        }
    }
}
