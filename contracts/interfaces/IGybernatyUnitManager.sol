// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

interface IGybernatyUnitManager {
    enum ActionType {
        CREATE_USER,
        LEVEL_UP,
        LEVEL_DOWN
    }

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

    event UserMarkedUp(address indexed userAddress, uint32 currentLevel, uint256 indexed timestamp);
    event UserMarkedDown(address indexed userAddress, uint32 currentLevel, uint256 indexed timestamp);
    event UserLevelChanged(address indexed userAddress, uint32 oldLevel, uint32 newLevel, uint256 indexed timestamp);
    event GybernatyJoined(address indexed gybernatyAddress, uint256 amount, uint256 indexed timestamp);
    event TokensWithdrawn(address indexed userAddress, uint256 amount, uint256 indexed timestamp);
    event UserCreated(address indexed userAddress, string name, uint32 level, uint256 indexed timestamp);
    event ActionProposed(bytes32 indexed actionId, address indexed initiator, ActionType actionType, uint256 timestamp);
    event ActionApproved(bytes32 indexed actionId, address indexed approver, uint256 timestamp);
    event ActionExecuted(bytes32 indexed actionId, uint256 timestamp);
    event ActionExpired(bytes32 indexed actionId, uint256 timestamp);

    function joinGybernaty() external payable;
    function proposeCreateUser(address userAddress, uint32 level, string calldata name, string calldata link) external;
    function approveAction(bytes32 actionId) external;
    function withdrawTokens(uint256 amount) external;
    function getUserLevel(address userAddress) external view returns (uint32);
    function getActionDetails(bytes32 actionId) external view returns (
        address initiator,
        address targetUser,
        ActionType actionType,
        uint32 proposedLevel,
        uint256 approvalsCount,
        bool isPending,
        uint256 createdAt
    );
}