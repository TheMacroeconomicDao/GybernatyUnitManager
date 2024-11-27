// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "../libraries/Constants.sol";
import "../libraries/Validation.sol";
import "../interfaces/IUserManager.sol";

contract UserManager is IUserManager, AccessControl {
    mapping(address => User) private users;
    
    error UserAlreadyExists(address userAddress);
    error UserDoesNotExist(address userAddress);
    error NotMarkedForChange(address userAddress);
    error LevelLimitReached(uint32 currentLevel);

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function createUser(
        address userAddress,
        uint32 level,
        string calldata name,
        string calldata link
    ) external override onlyRole(Constants.GYBERNATY_ROLE) {
        Validation.validateAddress(userAddress);
        Validation.validateLevel(level);
        Validation.validateString(name, Constants.MAX_NAME_LENGTH);
        Validation.validateString(link, Constants.MAX_LINK_LENGTH);

        if (users[userAddress].exists) {
            revert UserAlreadyExists(userAddress);
        }

        users[userAddress] = User({
            userAddress: userAddress,
            name: name,
            link: link,
            markedUp: false,
            markedDown: false,
            level: level,
            lastWithdrawTime: 0,
            withdrawCount: 0,
            exists: true,
            lastActionTime: block.timestamp
        });

        emit UserCreated(userAddress, name, level, block.timestamp);
    }

    function getUser(address userAddress) external view returns (User memory) {
        if (!users[userAddress].exists) {
            revert UserDoesNotExist(userAddress);
        }
        return users[userAddress];
    }

    function getUserLevel(address userAddress) external view returns (uint32) {
        return users[userAddress].level;
    }

    function userExists(address userAddress) external view returns (bool) {
        return users[userAddress].exists;
    }

    function updateUserLevel(address userAddress, uint32 newLevel) external onlyRole(Constants.GYBERNATY_ROLE) {
        User storage user = users[userAddress];
        if (!user.exists) {
            revert UserDoesNotExist(userAddress);
        }

        Validation.validateLevel(newLevel);
        
        uint32 oldLevel = user.level;
        user.level = newLevel;
        user.lastActionTime = block.timestamp;

        emit UserLevelChanged(userAddress, oldLevel, newLevel, block.timestamp);
    }
}