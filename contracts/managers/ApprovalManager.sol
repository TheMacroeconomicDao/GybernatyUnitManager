// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "../interfaces/IApprovalManager.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract ApprovalManager is IApprovalManager, AccessControl, Pausable {
    bytes32 public constant GYBERNATY_ROLE = keccak256("GYBERNATY_ROLE");
    uint256 private constant APPROVAL_TIMEOUT = 7 days;

    mapping(bytes32 => PendingAction) private pendingActions;
    mapping(bytes32 => mapping(uint32 => uint256)) private actionLevelApprovals;

    error ActionNotPending();
    error AlreadyApproved();
    error ActionExpired();
    error InsufficientApprovals();
    error InvalidActionType();

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function addApproval(bytes32 actionId) external override whenNotPaused returns (bool) {
        PendingAction storage action = pendingActions[actionId];
        if (!action.isPending) revert ActionNotPending();
        if (action.approvals[msg.sender]) revert AlreadyApproved();
        if (block.timestamp > action.createdAt + APPROVAL_TIMEOUT) {
            _expireAction(actionId);
            revert ActionExpired();
        }

        action.approvals[msg.sender] = true;
        action.approvalsCount++;

        if (hasRole(GYBERNATY_ROLE, msg.sender)) {
            actionLevelApprovals[actionId][4]++;
        }

        emit ActionApproved(actionId, msg.sender, block.timestamp);

        return _checkRequiredApprovals(action, actionId);
    }

    function _checkRequiredApprovals(
        PendingAction storage action,
        bytes32 actionId
    ) private view returns (bool) {
        if (hasRole(GYBERNATY_ROLE, msg.sender)) {
            return true;
        }

        if (action.targetLevel == 4) {
            return actionLevelApprovals[actionId][4] > 0;
        }

        uint32 requiredLevel1 = action.initiatorLevel + 1;
        uint32 requiredLevel2 = action.initiatorLevel + 2;

        return actionLevelApprovals[actionId][requiredLevel1] > 0 && 
               actionLevelApprovals[actionId][requiredLevel2] > 0;
    }

    function _expireAction(bytes32 actionId) private {
        PendingAction storage action = pendingActions[actionId];
        action.isPending = false;
        emit ActionExpired(actionId, block.timestamp);
    }

    function getActionDetails(bytes32 actionId) external view override returns (
        address initiator,
        address targetUser,
        ActionType actionType,
        uint32 proposedLevel,
        uint256 approvalsCount,
        bool isPending,
        uint256 createdAt
    ) {
        PendingAction storage action = pendingActions[actionId];
        return (
            action.initiator,
            action.targetUser,
            action.actionType,
            action.proposedLevel,
            action.approvalsCount,
            action.isPending,
            action.createdAt
        );
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }
}