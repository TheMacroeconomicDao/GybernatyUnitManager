// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../managers/UserManager.sol";
import "../managers/TokenManager.sol";
import "../managers/ApprovalManager.sol";
import "../libraries/Constants.sol";

/**
 * @title GybernatyUnitManager
 * @dev Main contract coordinating user management, token operations and approvals
 * @notice This contract serves as the entry point for all system operations
 * @custom:security-contact security@gybernaty.com
 */
contract GybernatyUnitManager is ReentrancyGuard, Pausable, AccessControl {
    /// @notice Manager handling user operations
    UserManager public userManager;
    
    /// @notice Manager handling token operations
    TokenManager public tokenManager;
    
    /// @notice Manager handling approval logic
    ApprovalManager public approvalManager;

    /**
     * @dev Contract constructor
     * @param _gbrToken Address of the GBR token contract
     * @param _levelLimits Array of withdrawal limits for each level
     */
    constructor(
        address _gbrToken,
        uint256[] memory _levelLimits
    ) {
        userManager = new UserManager();
        tokenManager = new TokenManager(_gbrToken, _levelLimits);
        approvalManager = new ApprovalManager();
        
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(Constants.GYBERNATY_ROLE, msg.sender);
    }

    /**
     * @notice Allows users to join as Gybernaty members
     * @dev Requires either GBR tokens or BNB payment
     */
    function joinGybernaty() external payable whenNotPaused {
        require(
            msg.value >= Constants.BNB_AMOUNT || 
            tokenManager.hasGbrTokens(msg.sender),
            "Insufficient payment"
        );
        
        _grantRole(Constants.GYBERNATY_ROLE, msg.sender);
        emit GybernatyJoined(msg.sender, msg.value);
    }

    /**
     * @notice Proposes creation of a new user
     * @param userAddress Address of the new user
     * @param level Proposed user level
     * @param name User's name
     * @param link User's profile link
     */
    function proposeCreateUser(
        address userAddress,
        uint32 level,
        string calldata name,
        string calldata link
    ) external whenNotPaused {
        require(level >= Constants.MIN_LEVEL && level <= Constants.MAX_LEVEL, "Invalid level");
        
        bytes32 actionId = approvalManager.proposeAction(
            msg.sender,
            userAddress,
            ApprovalManager.ActionType.CREATE_USER,
            level,
            name,
            link
        );
        
        emit ActionProposed(actionId, msg.sender, level);
    }

    /**
     * @notice Approves a pending action
     * @param actionId Identifier of the action to approve
     */
    function approveAction(bytes32 actionId) external whenNotPaused {
        uint32 approverLevel = userManager.getUserLevel(msg.sender);
        bool isGybernaty = hasRole(Constants.GYBERNATY_ROLE, msg.sender);
        
        if (approvalManager.approveAction(actionId, msg.sender, approverLevel, isGybernaty)) {
            executeAction(actionId);
        }
    }

    /**
     * @dev Internal function to execute approved actions
     * @param actionId Identifier of the action to execute
     */
    function executeAction(bytes32 actionId) internal {
        (
            address initiator,
            address targetUser,
            ApprovalManager.ActionType actionType,
            uint32 level,
            string memory name,
            string memory link
        ) = approvalManager.getActionDetails(actionId);

        if (actionType == ApprovalManager.ActionType.CREATE_USER) {
            userManager.createUser(targetUser, level, name, link);
        }
        
        emit ActionExecuted(actionId);
    }

    /**
     * @notice Allows users to withdraw tokens based on their level
     * @param amount Amount of tokens to withdraw
     */
    function withdrawTokens(uint256 amount) external nonReentrant whenNotPaused {
        uint32 userLevel = userManager.getUserLevel(msg.sender);
        tokenManager.withdrawTokens(msg.sender, amount, userLevel);
    }

    /// @notice Allows contract to receive BNB
    receive() external payable {}

    /// @notice Emitted when a new Gybernaty member joins
    event GybernatyJoined(address indexed gybernatyAddress, uint256 amount);
    
    /// @notice Emitted when a new action is proposed
    event ActionProposed(bytes32 indexed actionId, address indexed initiator, uint32 level);
    
    /// @notice Emitted when an action is executed
    event ActionExecuted(bytes32 indexed actionId);
}