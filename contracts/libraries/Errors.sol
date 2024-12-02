// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

library Errors {
    error InvalidLevel(uint32 level);
    error UserAlreadyExists(address userAddress);
    error UserDoesNotExist(address userAddress);
    error InsufficientPayment(uint256 provided, uint256 required);
    error InvalidStringLength(uint256 provided, uint256 maxAllowed);
    error ZeroAddress();
    error ActionNotPending();
    error AlreadyApproved();
    error ActionExpired();
    error InsufficientApprovals();
    error UnauthorizedApprover();
    error WithdrawalLimitExceeded(uint256 currentCount, uint256 maxCount);
    error InsufficientWithdrawalBalance(uint256 requested, uint256 available);
}