// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../managers/UserManager.sol";
import "../managers/TokenManager.sol";
import "../managers/ApprovalManager.sol";
import "../libraries/Constants.sol";
import "../interfaces/IGybernatyUnitManager.sol";

/**
 * @title GybernatyUnitManager
 * @dev Main contract coordinating user management, token operations and approvals
 * @notice This contract serves as the entry point for all system operations
 */
contract GybernatyUnitManager is IGybernatyUnitManager, ReentrancyGuard, Pausable, AccessControl {
    UserManager public immutable userManager;
    TokenManager public immutable tokenManager;
    ApprovalManager public immutable approvalManager;

    constructor(
        address _gbrToken,
        uint256[] memory _levelLimits
    ) {
        require(_gbrToken != address(0), "Invalid token address");
        require(_levelLimits.length == Constants.MAX_LEVEL, "Invalid limits length");

        userManager = new UserManager();
        tokenManager = new TokenManager(_gbrToken, _levelLimits);
        approvalManager = new ApprovalManager();
        
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(Constants.GYBERNATY_ROLE, msg.sender);
    }

    function joinGybernaty() external payable override whenNotPaused {
        require(
            msg.value >= Constants.BNB_AMOUNT || 
            tokenManager.hasGbrTokens(msg.sender),
            "Insufficient payment"
        );
        
        _grantRole(Constants.GYBERNATY_ROLE, msg.sender);
        emit GybernatyJoined(msg.sender, msg.value, block.timestamp);
    }

    function proposeCreateUser(
        address userAddress,
        uint32 level,
        string calldata name,
        string calldata link
    ) external override whenNotPaused {
        require(level >= Constants.MIN_LEVEL && level <= Constants.MAX_LEVEL, "Invalid level");
        
        bytes32 actionId = approvalManager.proposeAction(
            msg.sender,
            userAddress,
            ActionType.CREATE_USER,
            level,
            name,
            link
        );
        
        emit ActionProposed(actionId, msg.sender, ActionType.CREATE_USER, block.timestamp);
    }

    function approveAction(bytes32 actionId) external override whenNotPaused {
        uint32 approverLevel = userManager.getUserLevel(msg.sender);
        bool isGybernaty = hasRole(Constants.GYBERNATY_ROLE, msg.sender);
        
        if (approvalManager.approveAction(actionId, msg.sender, approverLevel, isGybernaty)) {
            _executeAction(actionId);
        }
    }

    function withdrawTokens(uint256 amount) external override nonReentrant whenNotPaused {
        uint32 userLevel = userManager.getUserLevel(msg.sender);
        tokenManager.withdrawTokens(msg.sender, amount, userLevel);
        emit TokensWithdrawn(msg.sender, amount, block.timestamp);
    }

    function _executeAction(bytes32 actionId) internal {
        (
            address initiator,
            address targetUser,
            ActionType actionType,
            uint32 level,
            string memory name,
            string memory link
        ) = approvalManager.getActionDetails(actionId);

        if (actionType == ActionType.CREATE_USER) {
            userManager.createUser(targetUser, level, name, link);
        }
        
        emit ActionExecuted(actionId, block.timestamp);
    }

    receive() external payable {}
}