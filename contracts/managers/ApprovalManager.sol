// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "../libraries/Constants.sol";
import "../interfaces/IApprovalManager.sol";

contract ApprovalManager is IApprovalManager, AccessControl {
    mapping(bytes32 => PendingAction) private pendingActions;
    mapping(bytes32 => mapping(uint32 => uint256)) private actionLevelApprovals;

    error ActionNotPending();
    error AlreadyApproved();
    error ActionExpired();
    error InsufficientApprovals();
    error UnauthorizedApprover();

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function proposeAction(
        address initiator,
        address targetUser,
        ActionType actionType,
        uint32 level,
        string memory name,
        string memory link
    ) external returns (bytes32) {
        bytes32 actionId = keccak256(
            abi.encodePacked(
                initiator,
                targetUser,
                actionType,
                level,
                block.timestamp
            )
        );

        PendingAction storage action = pendingActions[actionId];
        action.initiator = initiator;
        action.targetUser = targetUser;
        action.actionType = actionType;
        action.proposedLevel = level;
        action.name = name;
        action.link = link;
        action.isPending = true;
        action.createdAt = block.timestamp;

        return actionId;
    }

    function approveAction(
        bytes32 actionId,
        address approver,
        uint32 approverLevel,
        bool isGybernaty
    ) external returns (bool) {
        PendingAction storage action = pendingActions[actionId];
        
        if (!action.isPending) {
            revert ActionNotPending();
        }
        
        if (action.approvals[approver]) {
            revert AlreadyApproved();
        }
        
        if (block.timestamp > action.createdAt + Constants.APPROVAL_TIMEOUT) {
            action.isPending = false;
            emit ActionExpired(actionId, block.timestamp);
            revert ActionExpired();
        }

        action.approvals[approver] = true;
        action.approvalsCount++;
        actionLevelApprovals[actionId][approverLevel]++;

        emit ActionApproved(actionId, approver, block.timestamp);

        return _checkRequiredApprovals(actionId, approverLevel, isGybernaty);
    }

    function _checkRequiredApprovals(
        bytes32 actionId,
        uint32 approverLevel,
        bool isGybernaty
    ) private view returns (bool) {
        if (isGybernaty) {
            return true;
        }

        PendingAction storage action = pendingActions[actionId];
        if (action.proposedLevel == Constants.MAX_LEVEL) {
            return false; // Требуется подтверждение только от Gybernaty
        }

        uint32 requiredLevel1 = action.proposedLevel + 1;
        uint32 requiredLevel2 = action.proposedLevel + 2;

        return actionLevelApprovals[actionId][requiredLevel1] > 0 && 
               actionLevelApprovals[actionId][requiredLevel2] > 0;
    }

    function getActionDetails(bytes32 actionId) external view returns (
        address initiator,
        address targetUser,
        ActionType actionType,
        uint32 proposedLevel,
        string memory name,
        string memory link
    ) {
        PendingAction storage action = pendingActions[actionId];
        return (
            action.initiator,
            action.targetUser,
            action.actionType,
            action.proposedLevel,
            action.name,
            action.link
        );
    }
}