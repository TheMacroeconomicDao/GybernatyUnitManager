// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "../interfaces/IUserManager.sol";

contract UserManager is IUserManager, AccessControl {
    mapping(address => User) private users;
    
    bytes32 public constant GYBERNATY_ROLE = keccak256("GYBERNATY_ROLE");
    uint32 public constant MAX_LEVEL = 4;
    uint32 public constant MIN_LEVEL = 1;

    error InvalidLevel(uint32 level);
    error UserAlreadyExists(address userAddress);
    error UserDoesNotExist(address userAddress);
    error InvalidStringLength();

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function createUser(
        address userAddress,
        uint32 level,
        string calldata name,
        string calldata link
    ) external override onlyRole(GYBERNATY_ROLE) {
        if (bytes(name).length == 0 || bytes(name).length > 100) revert InvalidStringLength();
        if (bytes(link).length > 200) revert InvalidStringLength();
        if (users[userAddress].exists) revert UserAlreadyExists(userAddress);
        if (level < MIN_LEVEL || level > MAX_LEVEL) revert InvalidLevel(level);

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
        if (!users[userAddress].exists) revert UserDoesNotExist(userAddress);
        return users[userAddress];
    }

    function getUserLevel(address userAddress) external view returns (uint32) {
        return users[userAddress].level;
    }

    function userExists(address userAddress) external view returns (bool) {
        return users[userAddress].exists;
    }
}