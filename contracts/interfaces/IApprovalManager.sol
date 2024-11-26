// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

interface IApprovalManager {
    enum ActionType {
        CREATE_USER,
        LEVEL_UP,
        LEVEL_DOWN
    }

    struct PendingAction {
        address initiator;
        address targetUser;
        ActionType actionType;
        uint32 proposedLevel;
        string name;
        string link;
        bool isPending;
        uint256 createdAt;
        mapping(address => bool) approvals;
        mapping(uint32 => uint256) levelApprovals;
        uint256 approvalsCount;
        uint32 initiatorLevel;
        uint32 targetLevel;
    }

    event ActionApproved(bytes32 indexed actionId, address indexed approver, uint256 timestamp);
    event ActionExecuted(bytes32 indexed actionId, uint256 timestamp);
    event ActionExpired(bytes32 indexed actionId, uint256 timestamp);

    function addApproval(bytes32 actionId) external returns (bool);
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