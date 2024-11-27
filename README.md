# Gybernaty Unit Manager

## Overview
Gybernaty Unit Manager is a decentralized hierarchical user management system with multi-level approval mechanisms. The system implements a sophisticated token management system with level-based withdrawal limits and approval requirements.

## Key Features

### Hierarchical User Management
- 4 user levels with increasing privileges
- Gybernaty role with administrative powers
- Multi-level approval system for user actions

### Token Management
- Level-based withdrawal limits
- Monthly withdrawal restrictions
- Secure token transfer mechanisms

### Approval System
- Multi-signature style approvals
- Time-limited pending actions
- Level-based approval requirements

## Architecture

### Core Components

#### GybernatyUnitManager
Main contract coordinating all system components:
- User management
- Token operations
- Approval processing

#### Managers
1. **UserManager**
   - User creation and updates
   - Level management
   - User data storage

2. **TokenManager**
   - Token withdrawals
   - Limit management
   - Monthly restrictions

3. **ApprovalManager**
   - Action proposals
   - Approval tracking
   - Multi-level confirmations

### Libraries
1. **Constants**
   - System-wide configuration
   - Security parameters
   - Time constraints

2. **Validation**
   - Input validation
   - Security checks
   - Data integrity

## Security Features

### Access Control
- Role-based permissions
- Hierarchical approval system
- Time-locked actions

### Safety Mechanisms
- Reentrancy protection
- Pausable operations
- Input validation

## Technical Documentation

### Installation
```bash
npm install
```

### Testing
```bash
npm run test
```

### Deployment
```bash
npm run deploy
```

## Usage Examples

### Joining as Gybernaty
```solidity
// Using GBR tokens
await gbrToken.approve(contractAddress, GBR_TOKEN_AMOUNT);
await contract.joinGybernaty();

// Using BNB
await contract.joinGybernaty({ value: BNB_AMOUNT });
```

### Creating Users
```solidity
const actionId = await contract.proposeCreateUser(
    userAddress,
    2, // level
    "User Name",
    "https://example.com/profile"
);
```

### Approving Actions
```solidity
await contract.approveAction(actionId);
```

## Error Codes

| Error Code | Description |
|------------|-------------|
| UserAlreadyExists | User address is already registered |
| InvalidLevel | Requested level is out of bounds |
| ActionExpired | Approval timeout reached |
| InsufficientApprovals | Not enough approvals for action |

## Events

| Event | Description |
|-------|-------------|
| GybernatyJoined | New Gybernaty member joined |
| ActionProposed | New action proposed |
| ActionExecuted | Action successfully executed |
| UserCreated | New user registered |

## License
MIT