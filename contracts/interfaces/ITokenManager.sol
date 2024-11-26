// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

interface ITokenManager {
    event TokensWithdrawn(address indexed userAddress, uint256 amount, uint256 indexed timestamp);
    
    function withdrawTokens(uint256 amount) external;
}