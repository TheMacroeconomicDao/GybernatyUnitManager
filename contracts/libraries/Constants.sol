// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

/**
 * @title Constants
 * @dev Central storage for all system constants
 */
library Constants {
    // Roles
    bytes32 public constant GYBERNATY_ROLE = keccak256("GYBERNATY_ROLE");
    
    // Level constraints
    uint32 public constant MAX_LEVEL = 4;
    uint32 public constant MIN_LEVEL = 1;
    
    // Token amounts
    uint256 public constant GBR_TOKEN_AMOUNT = 1_000_000_000_000;
    uint256 public constant BNB_AMOUNT = 1000 ether;
    
    // Time constraints
    uint256 public constant MONTH_IN_SECONDS = 30 days;
    uint256 public constant APPROVAL_TIMEOUT = 7 days;
    
    // Withdrawal limits
    uint256 public constant MAX_MONTHLY_WITHDRAWALS = 2;
    
    // String length limits
    uint256 public constant MAX_NAME_LENGTH = 100;
    uint256 public constant MAX_LINK_LENGTH = 200;
}