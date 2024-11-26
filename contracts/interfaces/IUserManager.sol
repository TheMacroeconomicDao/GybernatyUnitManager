// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

interface IUserManager {
    struct User {
        address userAddress;
        string name;
        string link;
        bool markedUp;
        bool markedDown;
        uint32 level;
        uint256 lastWithdrawTime;
        uint256 withdrawCount;
        bool exists;
        uint256 lastActionTime;
    }

    event UserCreated(address indexed userAddress, string name, uint32 level, uint256 indexed timestamp);
    event UserLevelChanged(address indexed userAddress, uint32 oldLevel, uint32 newLevel, uint256 indexed timestamp);

    function createUser(address userAddress, uint32 level, string calldata name, string calldata link) external;
    function getUser(address userAddress) external view returns (User memory);
    function getUserLevel(address userAddress) external view returns (uint32);
    function userExists(address userAddress) external view returns (bool);
}