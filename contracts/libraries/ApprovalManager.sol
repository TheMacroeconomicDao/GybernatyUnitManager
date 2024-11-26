// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "../interfaces/IGybernatyUnitManager.sol";

library ApprovalManager {
    struct PendingAction {
        address initiator;
        address targetUser;
        IGybernatyUnitManager.ActionType actionType;
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

    error InsufficientApprovals();
    error AlreadyApproved();
    error ActionExpiredError();
    error UnauthorizedApprover();
    error InvalidApproverLevel();
    error Level4RequiresGybernaty();

    function addApproval(
        PendingAction storage action,
        address approver,
        uint32 approverLevel,
        bool isGybernaty,
        uint256 timeout
    ) internal returns (bool isFullyApproved) {
        if (action.approvals[approver]) revert AlreadyApproved();
        if (block.timestamp > action.createdAt + timeout) revert ActionExpiredError();
        
        // Действия с уровнем 4 требуют подтверждения только от Gybernaty
        if (action.targetLevel == 4 && !isGybernaty) {
            revert Level4RequiresGybernaty();
        }

        // Для остальных уровней проверяем стандартную логику
        if (!isGybernaty) {
            uint32 requiredMinLevel = action.initiatorLevel + 1;
            uint32 requiredMaxLevel = action.initiatorLevel + 2;
            
            if (approverLevel < requiredMinLevel || approverLevel > requiredMaxLevel) {
                revert InvalidApproverLevel();
            }
        }

        action.approvals[approver] = true;
        action.levelApprovals[approverLevel]++;
        action.approvalsCount++;

        return _checkRequiredApprovals(action, isGybernaty);
    }

    function _checkRequiredApprovals(
        PendingAction storage action,
        bool isGybernaty
    ) private view returns (bool) {
        // Gybernaty может подтвердить любое действие самостоятельно
        if (isGybernaty) {
            return true;
        }

        // Действия с уровнем 4 требуют только подтверждения Gybernaty
        if (action.targetLevel == 4) {
            return false;
        }

        uint32 requiredLevel1 = action.initiatorLevel + 1;
        uint32 requiredLevel2 = action.initiatorLevel + 2;

        return action.levelApprovals[requiredLevel1] > 0 && 
               action.levelApprovals[requiredLevel2] > 0;
    }
}