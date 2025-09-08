# FTH Core API Documentation

## 📚 Contract Interfaces

This documentation covers all smart contract interfaces for the FTH Core ecosystem.

## 🎯 FTHCore Contract

The main token contract implementing ERC20 with gold backing functionality.

### Contract Address
- **Mainnet**: `TBD`
- **Testnet**: `TBD`

### Core Functions

#### `depositGold(uint256 grams)`
Deposits gold reserves to back new tokens.

**Parameters:**
- `grams`: Amount of gold in grams (18 decimals)

**Requirements:**
- Only authorized operators
- Rate limited (1 hour cooldown)
- Contract not paused

**Events:**
- `GoldDeposited(address indexed operator, uint256 amount, uint256 timestamp)`

**Example:**
```solidity
// Deposit 1000 grams of gold
fthCore.depositGold(1000 * 1e18);
```

#### `withdrawGold(uint256 grams)`
Withdraws gold reserves while maintaining backing ratio.

**Parameters:**
- `grams`: Amount of gold to withdraw (18 decimals)

**Requirements:**
- Only authorized operators
- Sufficient gold reserves
- Maintains 1:1 backing ratio
- Rate limited

**Events:**
- `GoldWithdrawn(address indexed operator, uint256 amount, uint256 timestamp)`

#### `mint(address to, uint256 amount)`
Mints new FTHC tokens backed by gold reserves.

**Parameters:**
- `to`: Recipient address
- `amount`: Amount of tokens to mint (18 decimals)

**Requirements:**
- Only authorized operators
- Sufficient gold backing
- Under maximum supply
- Rate limited

**Events:**
- `TokensMinted(address indexed to, uint256 amount, address indexed operator)`

#### `burn(uint256 amount)`
Burns tokens from caller's balance.

**Parameters:**
- `amount`: Amount of tokens to burn (18 decimals)

**Requirements:**
- Sufficient token balance
- Contract not paused

**Events:**
- `TokensBurned(address indexed from, uint256 amount)`

#### `updateGoldPrice(uint256 newPriceUSD)`
Updates the gold price used for USD valuations.

**Parameters:**
- `newPriceUSD`: New gold price in USD (8 decimals)

**Requirements:**
- Only authorized operators
- Price within reasonable bounds (0 < price <= $1000/gram)

**Events:**
- `GoldPriceUpdated(uint256 newPrice, uint256 timestamp)`

### View Functions

#### `backingRatio() → uint256`
Returns the current backing ratio.

**Returns:**
- Backing ratio in 18 decimals (1e18 = 100%)

**Example:**
```solidity
uint256 ratio = fthCore.backingRatio();
// ratio = 2e18 means 200% backing
```

#### `isFullyBacked() → bool`
Checks if tokens are fully backed by gold.

**Returns:**
- `true` if goldReserves >= totalSupply

#### `getTokenValueUSD() → uint256`
Returns USD value per token.

**Returns:**
- USD value with 8 decimals

#### `getTotalValueUSD() → uint256`
Returns total market cap in USD.

**Returns:**
- Total USD value with 8 decimals

#### `getMaxMintable() → uint256`
Returns maximum tokens that can be minted.

**Returns:**
- Maximum mintable amount in 18 decimals

#### `getOperationCooldownRemaining(address account) → uint256`
Returns cooldown time remaining for an account.

**Returns:**
- Remaining seconds until next operation allowed

### Emergency Functions

#### `toggleEmergencyMode()`
Toggles emergency mode (owner only).

**Effects:**
- Pauses/unpauses contract
- Restricts operations to owner only

#### `emergencyPause()`
Immediately pauses all operations (owner only).

#### `emergencyUnpause()`
Unpauses operations (owner only).

## 🏛️ FTHGovernance Contract

Decentralized governance for protocol decisions.

### Core Functions

#### `propose(string title, string description, address target, bytes callData) → uint256`
Creates a new governance proposal.

**Parameters:**
- `title`: Proposal title
- `description`: Detailed description
- `target`: Target contract address
- `callData`: Encoded function call

**Requirements:**
- Proposer must hold >= 100,000 FTHC tokens

**Returns:**
- Proposal ID

**Events:**
- `ProposalCreated(uint256 indexed proposalId, address indexed proposer, ...)`

#### `vote(uint256 proposalId, uint8 voteType)`
Votes on a proposal.

**Parameters:**
- `proposalId`: ID of proposal to vote on
- `voteType`: 0 = Against, 1 = For, 2 = Abstain

**Requirements:**
- Voting period is active
- Voter has not already voted
- Voter has voting power (FTHC balance)

**Events:**
- `VoteCast(uint256 indexed proposalId, address indexed voter, VoteType voteType, uint256 weight)`

#### `execute(uint256 proposalId)`
Executes a successful proposal after delay.

**Parameters:**
- `proposalId`: ID of proposal to execute

**Requirements:**
- Proposal succeeded
- Execution delay has passed (2 days)
- Not already executed

**Events:**
- `ProposalExecuted(uint256 indexed proposalId)`

### View Functions

#### `getProposalState(uint256 proposalId) → ProposalState`
Returns current state of a proposal.

**Returns:**
- `0`: Pending
- `1`: Active
- `2`: Cancelled
- `3`: Defeated
- `4`: Succeeded
- `5`: Executed

#### `getProposalVotes(uint256 proposalId) → (uint256, uint256, uint256)`
Returns vote counts for a proposal.

**Returns:**
- `forVotes`: Votes in favor
- `againstVotes`: Votes against
- `abstainVotes`: Abstain votes

## 🥇 FTHStaking Contract

Staking contract for earning rewards on FTHC tokens.

### Core Functions

#### `stake(uint256 amount)`
Stakes FTHC tokens to earn rewards.

**Parameters:**
- `amount`: Amount of tokens to stake (18 decimals)

**Requirements:**
- Amount >= 1,000 FTHC (minimum stake)
- Sufficient token balance
- Approval for staking contract

**Events:**
- `Staked(address indexed user, uint256 amount)`

#### `unstake(uint256 amount)`
Unstakes tokens after lock period.

**Parameters:**
- `amount`: Amount of tokens to unstake

**Requirements:**
- Sufficient staked amount
- Lock period expired (30 days)

**Events:**
- `Unstaked(address indexed user, uint256 amount)`

#### `claimRewards()`
Claims pending staking rewards.

**Events:**
- `RewardClaimed(address indexed user, uint256 amount)`

### View Functions

#### `calculateRewards(address user) → uint256`
Calculates pending rewards for a user.

**Returns:**
- Pending reward amount in 18 decimals

#### `getStakeInfo(address user) → (uint256, uint256, uint256, uint256)`
Returns complete staking information for a user.

**Returns:**
- `amount`: Staked amount
- `startTime`: Stake start timestamp
- `lockExpiryTime`: When lock period expires
- `pendingRewards`: Current pending rewards

#### `getAPY() → uint256`
Returns current annual percentage yield.

**Returns:**
- APY in basis points (500 = 5%)

## 🌐 FTHOracle Contract

Oracle system for gold price feeds.

### Core Functions

#### `submitPrice(uint256 price)`
Submits gold price from oracle (oracles only).

**Parameters:**
- `price`: Gold price in USD with 8 decimals

**Requirements:**
- Only active oracles
- Price within deviation limits

**Events:**
- `PriceUpdated(address indexed oracle, uint256 price, uint256 timestamp)`

#### `addOracle(address oracle, uint256 weight)`
Adds new oracle to the system (owner only).

**Parameters:**
- `oracle`: Oracle address
- `weight`: Oracle weight in basis points

**Events:**
- `OracleAdded(address indexed oracle, uint256 weight)`

### View Functions

#### `getLatestPrice() → (uint256, uint256, bool)`
Returns latest aggregated gold price.

**Returns:**
- `price`: Price in USD with 8 decimals
- `timestamp`: Last update timestamp
- `isValid`: Whether price is valid and fresh

#### `getOracleInfo(address oracle) → (bool, uint256, uint256, uint256)`
Returns information about an oracle.

**Returns:**
- `isActive`: Whether oracle is active
- `weight`: Oracle weight in basis points
- `lastPrice`: Last submitted price
- `lastUpdate`: Last update timestamp

## 🛡️ FTHMultiSig Contract

Multi-signature wallet for critical operations.

### Core Functions

#### `submitTransaction(address to, uint256 value, bytes data) → uint256`
Submits a transaction for multi-sig approval.

**Parameters:**
- `to`: Target contract address
- `value`: ETH value to send
- `data`: Encoded function call

**Requirements:**
- Only owners can submit

**Returns:**
- Transaction ID

**Events:**
- `Submission(uint256 indexed transactionId)`

#### `confirmTransaction(uint256 transactionId)`
Confirms a submitted transaction.

**Parameters:**
- `transactionId`: ID of transaction to confirm

**Requirements:**
- Only owners
- Not already confirmed by sender
- Transaction exists

**Events:**
- `Confirmation(address indexed sender, uint256 indexed transactionId)`

### View Functions

#### `isConfirmed(uint256 transactionId) → bool`
Checks if transaction has enough confirmations.

**Returns:**
- `true` if confirmations >= required

#### `getConfirmationCount(uint256 transactionId) → uint256`
Returns number of confirmations for a transaction.

**Returns:**
- Current confirmation count

## 🔗 Integration Examples

### Web3.js Integration

```javascript
const Web3 = require('web3');
const web3 = new Web3('https://mainnet.infura.io/v3/YOUR_KEY');

// Contract instances
const fthCore = new web3.eth.Contract(FTH_CORE_ABI, FTH_CORE_ADDRESS);
const staking = new web3.eth.Contract(STAKING_ABI, STAKING_ADDRESS);
const governance = new web3.eth.Contract(GOV_ABI, GOV_ADDRESS);

// Check user balance and backing
async function getUserInfo(userAddress) {
    const balance = await fthCore.methods.balanceOf(userAddress).call();
    const backingRatio = await fthCore.methods.backingRatio().call();
    const goldPrice = await fthCore.methods.goldPriceUSD().call();
    
    return {
        balance: web3.utils.fromWei(balance),
        backingRatio: (backingRatio / 1e18 * 100).toFixed(2) + '%',
        usdValue: (balance * goldPrice / 1e26).toFixed(2)
    };
}

// Stake tokens
async function stakeTokens(amount, userAddress, privateKey) {
    const stakeAmount = web3.utils.toWei(amount.toString());
    
    // Approve staking contract
    const approveData = fthCore.methods.approve(STAKING_ADDRESS, stakeAmount).encodeABI();
    await sendTransaction(FTH_CORE_ADDRESS, approveData, userAddress, privateKey);
    
    // Stake tokens
    const stakeData = staking.methods.stake(stakeAmount).encodeABI();
    await sendTransaction(STAKING_ADDRESS, stakeData, userAddress, privateKey);
}
```

### Ethers.js Integration

```javascript
const { ethers } = require('ethers');

// Provider and signer
const provider = new ethers.providers.JsonRpcProvider('https://mainnet.infura.io/v3/YOUR_KEY');
const signer = new ethers.Wallet(PRIVATE_KEY, provider);

// Contract instances
const fthCore = new ethers.Contract(FTH_CORE_ADDRESS, FTH_CORE_ABI, signer);
const staking = new ethers.Contract(STAKING_ADDRESS, STAKING_ABI, signer);

// Monitor events
function monitorEvents() {
    // Listen for token mints
    fthCore.on('TokensMinted', (to, amount, operator) => {
        console.log(`${ethers.utils.formatEther(amount)} FTHC minted to ${to}`);
    });
    
    // Listen for staking events
    staking.on('Staked', (user, amount) => {
        console.log(`${ethers.utils.formatEther(amount)} FTHC staked by ${user}`);
    });
}

// Vote on governance proposal
async function voteOnProposal(proposalId, voteType) {
    const governance = new ethers.Contract(GOV_ADDRESS, GOV_ABI, signer);
    const tx = await governance.vote(proposalId, voteType);
    await tx.wait();
    console.log(`Voted ${voteType} on proposal ${proposalId}`);
}
```

## 📊 Error Codes

### Common Errors

| Error | Description | Solution |
|-------|-------------|----------|
| `Not authorized` | Caller lacks required permissions | Use authorized account |
| `Insufficient gold backing` | Not enough gold to mint tokens | Deposit more gold first |
| `Would break backing ratio` | Operation would violate 1:1 ratio | Reduce withdrawal amount |
| `Operation too frequent` | Rate limit exceeded | Wait for cooldown period |
| `Emergency mode: owner only` | Contract in emergency mode | Wait for normal mode |
| `Insufficient tokens to propose` | Need 100k FTHC to propose | Acquire more tokens |
| `Voting not started` | Proposal voting period not active | Wait for voting to start |
| `Amount below minimum stake` | Stake amount too small | Stake at least 1000 FTHC |
| `Lock period not expired` | Cannot unstake during lock | Wait for lock to expire |

### Debug Tips

1. **Check Contract State**: Verify if contract is paused
2. **Verify Balances**: Ensure sufficient token/ETH balances
3. **Check Allowances**: Verify token approvals for contracts
4. **Gas Estimation**: Use proper gas limits for transactions
5. **Event Logs**: Monitor events for transaction details

## 🔧 Gas Optimization

### Recommended Gas Limits

| Function | Gas Limit | Description |
|----------|-----------|-------------|
| `transfer` | 65,000 | Standard ERC20 transfer |
| `depositGold` | 75,000 | Gold deposit with events |
| `mint` | 150,000 | Token minting with checks |
| `stake` | 200,000 | Staking with calculations |
| `vote` | 120,000 | Governance voting |
| `claimRewards` | 100,000 | Reward claiming |

### Gas Optimization Tips

1. **Batch Operations**: Group multiple calls when possible
2. **Approve Once**: Set high allowance to avoid repeated approvals
3. **Use Multicall**: Combine operations in single transaction
4. **Monitor Gas Prices**: Use appropriate gas prices for urgency
5. **Estimate First**: Always estimate gas before sending

---

*Complete API documentation for the FTH Core ecosystem. For support, visit our [Discord](https://discord.gg/fthcore).*