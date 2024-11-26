# Документация контракта GybernatyUnitManager

## Общее описание

GybernatyUnitManager - это смарт-контракт, реализующий иерархическую систему управления пользователями с различными уровнями доступа и возможностями. Контракт обеспечивает безопасное управление токенами и уровнями пользователей с системой подтверждений.

## Основные возможности

### 1. Система ролей и уровней

- **Уровни пользователей**: от MIN_LEVEL до MAX_LEVEL
- **Роль Gybernaty**: специальная роль с максимальными правами
- **Иерархическое управление**: пользователи могут управлять только теми, кто ниже их по уровню

### 2. Управление пользователями

#### Создание пользователей
```solidity
function proposeCreateUser(
    address userAddress,
    uint32 level,
    string calldata name,
    string calldata link
)
```
- Создание нового пользователя требует подтверждения
- Проверяется валидность адреса и уровня
- Имя пользователя ограничено 100 символами
- Ссылка ограничена 200 символами

#### Изменение уровня
- Повышение уровня требует подтверждения от пользователей более высокого уровня
- Понижение уровня может быть инициировано Gybernaty или пользователями выше уровнем

### 3. Система подтверждений

#### Процесс подтверждения
```solidity
function approveAction(bytes32 actionId)
```
- Каждое действие требует определенного количества подтверждений
- Действия имеют срок действия (APPROVAL_TIMEOUT = 7 дней)
- Gybernaty могут подтверждать любые действия

### 4. Управление токенами

#### Вывод токенов
```solidity
function withdrawTokens(uint256 amount)
```
- Лимиты на вывод зависят от уровня пользователя
- Ограничение на количество выводов в месяц
- Защита от повторного входа (reentrancy)

## Безопасность

### Защитные механизмы

1. **Защита от повторного входа**
   - Использование модификатора nonReentrant
   - Безопасная последовательность операций

2. **Проверки доступа**
   - Модификаторы для проверки уровня пользователя
   - Система ролей на основе AccessControl

3. **Временные ограничения**
   - Таймаут для подтверждений
   - Ограничения на количество выводов в месяц

### Защита от типовых атак

1. **Переполнение**
   - Использование SafeMath через Solidity 0.8+
   - Проверки на граничные значения

2. **Манипуляция временем**
   - Использование block.timestamp только для некритичных операций
   - Защита от манипуляций с временными метками

## События

```solidity
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
```

## Ошибки

```solidity
error InvalidLevel(uint32 level);
error UserAlreadyExists(address userAddress);
error UserDoesNotExist(address userAddress);
error NotMarkedForChange(address userAddress);
error LevelLimitReached(uint32 currentLevel);
error InsufficientPayment(uint256 provided, uint256 required);
error WithdrawalLimitExceeded(uint256 currentCount, uint256 maxCount);
error InsufficientWithdrawalBalance(uint256 requested, uint256 available);
error InvalidWithdrawalAmount();
error InsufficientLevel(uint32 requiredLevel);
error ActionNotPending();
error AlreadyApproved();
error UnauthorizedApprover();
error ActionExpiredError();
error InvalidStringLength();
error ZeroAddress();
error InsufficientApprovals();
```

## Примеры использования

### 1. Присоединение к системе как Gybernaty

```javascript
// Вариант с GBR токенами
await gbrToken.approve(contractAddress, GBR_TOKEN_AMOUNT);
await contract.joinGybernaty();

// Вариант с BNB
await contract.joinGybernaty({ value: BNB_AMOUNT });
```

### 2. Создание нового пользователя

```javascript
const actionId = await contract.proposeCreateUser(
    userAddress,
    2, // уровень
    "Имя пользователя",
    "https://example.com/profile"
);
```

### 3. Подтверждение действия

```javascript
await contract.approveAction(actionId);
```

## Лимиты и константы

- MAX_LEVEL: Максимальный уровень пользователя
- MIN_LEVEL: Минимальный уровень пользователя
- GBR_TOKEN_AMOUNT: Количество токенов для получения роли Gybernaty
- BNB_AMOUNT: Количество BNB для получения роли Gybernaty
- MAX_MONTHLY_WITHDRAWALS: Максимальное количество выводов в месяц
- APPROVAL_TIMEOUT: Время действия предложенного действия (7 дней)
- MIN_APPROVALS_REQUIRED: Минимальное количество подтверждений

## Рекомендации по развертыванию

1. Установите корректные значения констант при деплое:
   - Уровни доступа
   - Лимиты токенов
   - Количество подтверждений

2. Настройте начальные роли:
   - Назначьте администратора
   - Добавьте начальных Gybernaty

3. Проверьте лимиты на вывод токенов для каждого уровня

## Аудит и безопасность

### Рекомендации по аудиту

1. Проверить все модификаторы доступа
2. Проверить корректность расчета временных интервалов
3. Проверить логику подтверждений
4. Проверить обработку граничных случаев

### Потенциальные риски

1. Централизация управления
2. Временные атаки
3. Манипуляции с подтверждениями