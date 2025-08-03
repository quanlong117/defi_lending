# Project 9: Simple Savings Pool Smart Contract

## 📋 Overview

A DeFi savings pool smart contract built on Stacks blockchain that allows users to deposit STX tokens and earn 5% annual interest. This is a simple, secure savings mechanism with compound interest support.

## 🎯 Features

### Core Functionality
- **Deposit STX**: Users can deposit STX tokens to start earning interest
- **Withdraw STX**: Users can withdraw their deposits plus earned interest anytime
- **Claim Interest**: Users can claim earned interest without withdrawing principal
- **Fixed Interest Rate**: 5% annual interest rate
- **Compound Interest**: Interest compounds automatically
- **Minimum Deposit**: 1 STX minimum deposit requirement

### Pool Management
- **Pool Statistics**: Track total deposits, interest paid, and active users
- **User History**: Complete transaction history for each user
- **Admin Controls**: Pool can be enabled/disabled by contract owner
- **Emergency Functions**: Admin emergency withdrawal capabilities

### Interest Calculation
- **Time-based Accrual**: Interest calculated based on blocks elapsed
- **Fair Distribution**: Interest distributed proportionally to deposits
- **Real-time Calculation**: Interest calculated dynamically based on current block height

## 🚀 Deployment Information

### Testnet Deployment
- **Contract Address**: `ST2GG7HZZHEB3JHQFXHKD65HZXVRRNV6AYTS2VGMS.savings-pool`
- **Deployer Address**: `ST2GG7HZZHEB3JHQFXHKD65HZXVRRNV6AYTS2VGMS`
- **Network**: Stacks Testnet
- **Transaction ID**: Available in deployment logs

### Contract Configuration
- **Annual Interest Rate**: 5%
- **Minimum Deposit**: 1,000,000 microSTX (1 STX)
- **Blocks Per Year**: 52,560 (approximately 10-minute blocks)
- **Precision**: 10,000 (for percentage calculations)

## 📖 Contract Functions

### Public Functions

#### `initialize-pool()`
Initializes the savings pool. Must be called by contract owner.

#### `deposit(amount: uint)`
Deposits STX tokens to earn interest.
- **Parameters**: `amount` - Amount in microSTX to deposit
- **Requirements**: Amount must be >= minimum deposit (1 STX)
- **Returns**: `(ok true)` on success

#### `withdraw(amount: uint)`
Withdraws deposited STX plus earned interest.
- **Parameters**: `amount` - Amount in microSTX to withdraw
- **Requirements**: Amount must be <= total available balance
- **Returns**: `(ok true)` on success

#### `claim-interest()`
Claims earned interest without withdrawing principal.
- **Returns**: `(ok interest-amount)` on success

#### `set-pool-enabled(enabled: bool)` (Admin only)
Enables or disables the pool.
- **Parameters**: `enabled` - Boolean to enable/disable pool

#### `emergency-withdraw(amount: uint)` (Admin only)
Emergency withdrawal function for admin.

### Read-Only Functions

#### `get-pool-stats()`
Returns comprehensive pool statistics including total deposits, interest paid, and configuration.

#### `get-contract-info()`
Returns contract metadata including name, version, and configuration.

#### `get-user-deposit(user: principal)`
Returns user's deposit information including amount, deposit block, and total interest earned.

#### `get-user-balance(user: principal)`
Returns user's current balance including deposited amount and earned interest.

#### `calculate-interest(user: principal)`
Calculates current earned interest for a user.

#### `get-user-history(user: principal)`
Returns user's transaction history.

#### `calculate-potential-interest(amount: uint, blocks: uint)`
Calculates potential interest for a given amount over specified blocks.

#### `is-pool-enabled()`
Returns whether the pool is currently enabled.

#### `get-total-value-locked()`
Returns total value locked in the pool.

## 🛠️ Usage Examples

### Using the Interaction Script

```bash
# Install dependencies
npm install

# Run the demo script
npx ts-node interact-testnet.ts
```

### Manual Contract Interaction

```typescript
import { callReadOnlyFunction, makeContractCall } from "@stacks/transactions";

// Get pool statistics
const poolStats = await callReadOnlyFunction({
  contractAddress: "ST2GG7HZZHEB3JHQFXHKD65HZXVRRNV6AYTS2VGMS",
  contractName: "savings-pool",
  functionName: "get-pool-stats",
  functionArgs: [],
  network: new StacksTestnet(),
  senderAddress: "YOUR_ADDRESS"
});

// Make a deposit
const depositTx = await makeContractCall({
  contractAddress: "ST2GG7HZZHEB3JHQFXHKD65HZXVRRNV6AYTS2VGMS",
  contractName: "savings-pool",
  functionName: "deposit",
  functionArgs: [uintCV(5000000)], // 5 STX
  senderKey: "YOUR_PRIVATE_KEY",
  network: new StacksTestnet(),
  anchorMode: AnchorMode.Any,
  fee: 15000,
});
```

## 🧪 Testing

### Run Tests
```bash
npm test
```

### Test Coverage
The test suite covers:
- Contract initialization
- Deposit functionality
- Withdrawal functionality
- Interest calculation
- Pool statistics
- Admin functions
- Error handling

## 📊 Interest Calculation

Interest is calculated using the following formula:

```
Annual Interest = (Deposit Amount × Annual Rate) / 100
Interest Per Block = Annual Interest / Blocks Per Year
Total Interest = Interest Per Block × Blocks Elapsed
```

### Example Calculation
- Deposit: 10 STX (10,000,000 microSTX)
- Annual Rate: 5%
- Time: 1000 blocks
- Annual Interest: 500,000 microSTX (0.5 STX)
- Interest Per Block: ~9.5 microSTX
- Total Interest for 1000 blocks: ~9,500 microSTX

## 🔒 Security Features

- **Access Control**: Admin functions restricted to contract owner
- **Input Validation**: All inputs validated for correctness
- **Minimum Deposit**: Prevents spam with minimum deposit requirement
- **Safe Math**: All calculations use safe arithmetic operations
- **Emergency Controls**: Admin can disable pool in emergencies

## 🚨 Important Notes

1. **Testnet Only**: This contract is deployed on testnet for testing purposes
2. **Educational Purpose**: This is a simplified DeFi contract for learning
3. **No Guarantees**: Interest payments depend on contract having sufficient STX balance
4. **Admin Controls**: Contract owner has emergency controls for security

## 📝 Error Codes

- `u100`: Owner only function
- `u101`: Insufficient balance
- `u102`: Invalid amount
- `u103`: No deposit found
- `u104`: Pool disabled
- `u105`: Below minimum deposit
- `u106`: List operation failed
- `u107`: No interest to claim

## 🔗 Links

- [Stacks Testnet Explorer](https://explorer.stacks.co/?chain=testnet)
- [Contract on Explorer](https://explorer.stacks.co/txid/CONTRACT_TX_ID?chain=testnet)
- [Stacks Documentation](https://docs.stacks.co/)
- [Clarity Language Reference](https://docs.stacks.co/clarity/)

This project is for educational purposes. Use at your own risk.
