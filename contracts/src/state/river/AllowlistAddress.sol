//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../../libraries/UnstructuredStorage.sol";
import "../../libraries/Errors.sol";
import "../../libraries/LibSanitize.sol";

library AllowlistAddress {
    bytes32 internal constant ALLOWLIST_ADDRESS_SLOT = bytes32(uint256(keccak256("river.state.allowlistAddress")) - 1);

    function get() internal view returns (address) {
        return UnstructuredStorage.getStorageAddress(ALLOWLIST_ADDRESS_SLOT);
    }

    function set(address newValue) internal {
        LibSanitize._notZeroAddress(newValue);
        UnstructuredStorage.setStorageAddress(ALLOWLIST_ADDRESS_SLOT, newValue);
    }
}
