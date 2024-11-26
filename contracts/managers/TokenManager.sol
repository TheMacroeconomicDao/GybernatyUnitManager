// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/ITokenManager.sol";
import "../interfaces/IUserManager.sol";

contract TokenManager is ITokenManager, ReentrancyGuard {
    IERC20 public immutable gbrToken;
    IUserManager public immutable userManager;
    
    uint256 public constant MAX_MONTHLY_WITHDRAWALS = 5;
    uint256 public constant MONTH_IN_SECONDS = 30 days;
    
    mapping(uint32 => uint256) private levelWithdrawLimits;
    mapping(address => mapping(uint256 => uint256)) private userMonthlyWithdrawals;

    error WithdrawalLimitExceeded(uint256 currentCount, uint256 maxCount);
    error InsufficientWithdrawalBalance(uint256 requested, uint256 available);
    error InvalidWithdrawalAmount();

    constructor(
        address _gbrToken,
        address _userManager,
        uint256[] memory _levelLimits
    ) {
        gbrToken = IERC20(_gbrToken);
        userManager = IUserManager(_userManager);
        
        for (uint32 i = 0; i < _levelLimits.length; i++) {
            levelWithdrawLimits[i + 1] = _levelLimits[i];
        }
    }

    function withdrawTokens(uint256 amount) external nonReentrant {
        if (amount == 0) revert InvalidWithdrawalAmount();
        
        uint32 userLevel = userManager.getUserLevel(msg.sender);
        uint256 monthlyLimit = levelWithdrawLimits[userLevel];
        
        if (amount > monthlyLimit) {
            revert InsufficientWithdrawalBalance(amount, monthlyLimit);
        }

        uint256 currentMonth = block.timestamp / MONTH_IN_SECONDS;
        if (userMonthlyWithdrawals[msg.sender][currentMonth] >= MAX_MONTHLY_WITHDRAWALS) {
            revert WithdrawalLimitExceeded(
                userMonthlyWithdrawals[msg.sender][currentMonth],
                MAX_MONTHLY_WITHDRAWALS
            );
        }

        userMonthlyWithdrawals[msg.sender][currentMonth]++;
        require(gbrToken.transfer(msg.sender, amount), "Token transfer failed");
        
        emit TokensWithdrawn(msg.sender, amount, block.timestamp);
    }
}