// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "./Constants.sol";
import "./Errors.sol";

/**
 * @title Validation
 * @dev Library for input validation functions
 */
library Validation {
    function validateLevel(uint32 level) internal pure {
        if (level < Constants.MIN_LEVEL || level > Constants.MAX_LEVEL) {
            revert Errors.InvalidLevel(level);
        }
    }

    function validateString(string memory str, uint256 maxLength) internal pure {
        uint256 length = bytes(str).length;
        if (length == 0 || length > maxLength) {
            revert Errors.InvalidStringLength(length, maxLength);
        }
    }

    function validateAddress(address addr) internal pure {
        if (addr == address(0)) {
            revert Errors.ZeroAddress();
        }
    }

    function validateWithdrawal(
        uint256 amount,
        uint256 limit,
        uint256 withdrawalCount,
        uint256 maxWithdrawals
    ) internal pure {
        if (amount > limit) {
            revert Errors.InsufficientWithdrawalBalance(amount, limit);
        }
        if (withdrawalCount >= maxWithdrawals) {
            revert Errors.WithdrawalLimitExceeded(withdrawalCount, maxWithdrawals);
        }
    }
}