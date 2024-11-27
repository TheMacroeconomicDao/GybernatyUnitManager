// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../libraries/Constants.sol";
import "../interfaces/ITokenManager.sol";

contract TokenManager is ITokenManager, ReentrancyGuard {
    IERC20 public immutable gbrToken;
    mapping(uint32 => uint256) private levelWithdrawLimits;
    mapping(address => mapping(uint256 => uint256)) private userMonthlyWithdrawals;

    error WithdrawalLimitExceeded(uint256 currentCount, uint256 maxCount);
    error InsufficientWithdrawalBalance(uint256 requested, uint256 available);
    error InvalidWithdrawalAmount();

    constructor(address _gbrToken, uint256[] memory _levelLimits) {
        require(_gbrToken != address(0), "Invalid token address");
        gbrToken = IERC20(_gbrToken);
        
        for (uint32 i = 0; i < _levelLimits.length; i++) {
            levelWithdrawLimits[i + 1] = _levelLimits[i];
        }
    }

    function hasGbrTokens(address user) external view returns (bool) {
        return gbrToken.balanceOf(user) >= Constants.GBR_TOKEN_AMOUNT;
    }

    function withdrawTokens(
        address user,
        uint256 amount,
        uint32 userLevel
    ) external override nonReentrant {
        if (amount == 0) {
            revert InvalidWithdrawalAmount();
        }

        uint256 maxAmount = levelWithdrawLimits[userLevel];
        if (amount > maxAmount) {
            revert InsufficientWithdrawalBalance(amount, maxAmount);
        }

        uint256 currentMonth = block.timestamp / Constants.MONTH_IN_SECONDS;
        if (userMonthlyWithdrawals[user][currentMonth] >= Constants.MAX_MONTHLY_WITHDRAWALS) {
            revert WithdrawalLimitExceeded(
                userMonthlyWithdrawals[user][currentMonth],
                Constants.MAX_MONTHLY_WITHDRAWALS
            );
        }

        userMonthlyWithdrawals[user][currentMonth]++;
        require(gbrToken.transfer(user, amount), "Token transfer failed");
        
        emit TokensWithdrawn(user, amount, block.timestamp);
    }
}