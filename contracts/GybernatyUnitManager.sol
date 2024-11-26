// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./interfaces/IGybernatyUnitManager.sol";
import "./libraries/ApprovalManager.sol";

contract GybernatyUnitManager is IGybernatyUnitManager, ReentrancyGuard, Pausable, AccessControl {
    using Counters for Counters.Counter;
    using Address for address;
    using ApprovalManager for ApprovalManager.PendingAction;

    bytes32 public constant GYBERNATY_ROLE = keccak256("GYBERNATY_ROLE");
    uint256 private constant APPROVAL_TIMEOUT = 7 days;

    // State variables and other code remains the same...

    function proposeCreateUser(
        address userAddress,
        uint32 level,
        string calldata name,
        string calldata link
    ) external override whenNotPaused {
        if (bytes(name).length == 0 || bytes(name).length > 100) revert InvalidStringLength();
        if (bytes(link).length > 200) revert InvalidStringLength();
        if (users[userAddress].exists) revert UserAlreadyExists(userAddress);
        if (level < MIN_LEVEL || level > MAX_LEVEL) revert InvalidLevel(level);

        // Только Gybernaty может создавать пользователей 4 уровня
        if (level == 4 && !hasRole(GYBERNATY_ROLE, msg.sender)) {
            revert InsufficientLevel();
        }

        uint32 initiatorLevel = users[msg.sender].level;
        if (initiatorLevel == 0 && !hasRole(GYBERNATY_ROLE, msg.sender)) {
            revert InsufficientLevel();
        }
        if (level >= initiatorLevel && !hasRole(GYBERNATY_ROLE, msg.sender)) {
            revert InvalidLevel(level);
        }

        bytes32 actionId = _createActionId(ActionType.CREATE_USER, userAddress);
        ApprovalManager.PendingAction storage action = pendingActions[actionId];
        
        action.initiator = msg.sender;
        action.targetUser = userAddress;
        action.actionType = ActionType.CREATE_USER;
        action.proposedLevel = level;
        action.name = name;
        action.link = link;
        action.isPending = true;
        action.createdAt = block.timestamp;
        action.initiatorLevel = initiatorLevel;
        action.targetLevel = level;

        emit ActionProposed(actionId, msg.sender, ActionType.CREATE_USER, block.timestamp);
    }

    function approveAction(bytes32 actionId) external override whenNotPaused {
        ApprovalManager.PendingAction storage action = pendingActions[actionId];
        if (!action.isPending) revert ActionNotPending();

        uint32 approverLevel = users[msg.sender].level;
        bool isGybernaty = hasRole(GYBERNATY_ROLE, msg.sender);
        
        if (approverLevel == 0 && !isGybernaty) {
            revert InsufficientLevel();
        }

        bool isFullyApproved = action.addApproval(
            msg.sender,
            approverLevel,
            isGybernaty,
            APPROVAL_TIMEOUT
        );
        
        emit ActionApproved(actionId, msg.sender, block.timestamp);

        if (isFullyApproved) {
            _executeAction(actionId);
        }
    }

    // Rest of the contract implementation remains the same...
}