// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "./Constants.sol";

library Validation {
    error InvalidLevel(uint32 level);
    error InvalidStringLength();
    error ZeroAddress();

    function validateLevel(uint32 level) internal pure {
        if (level < Constants.MIN_LEVEL || level > Constants.MAX_LEVEL) {
            revert InvalidLevel(level);
        }
    }

    function validateString(string memory str, uint256 maxLength) internal pure {
        if (bytes(str).length == 0 || bytes(str).length > maxLength) {
            revert InvalidStringLength();
        }
    }

    function validateAddress(address addr) internal pure {
        if (addr == address(0)) {
            revert ZeroAddress();
        }
    }
}