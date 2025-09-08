# FTH Core User Guide

## 🌟 Welcome to FTH Core

FTH Core (FTHC) is a revolutionary gold-backed cryptocurrency where each token represents exactly 1 gram of physical gold. This guide will help you understand and use the FTH Core ecosystem.

## 🏁 Getting Started

### What is FTHC?
- **1 FTHC = 1 gram of gold** - Simple and transparent
- **Fully backed** - Every token is backed by real physical gold
- **Transparent** - All operations are recorded on the blockchain
- **Secure** - Multiple layers of security and validation

### Key Benefits
- 🔒 **Secure**: Built on battle-tested smart contracts
- 📊 **Transparent**: Real-time backing ratio visibility
- 💰 **Stable**: Backed by physical gold reserves
- 🌍 **Global**: Accessible 24/7 from anywhere
- 🔄 **Liquid**: Tradeable on decentralized exchanges

## 💳 How to Get FTHC Tokens

### Primary Market (Minting)
1. **Gold Deposit**: Authorized validators deposit physical gold
2. **Verification**: Gold reserves are verified and recorded
3. **Token Minting**: FTHC tokens are minted 1:1 with gold grams
4. **Distribution**: Tokens are distributed to purchasers

### Secondary Market
- **DEXs**: Trade on Uniswap, SushiSwap, and other DEXs
- **CEXs**: Available on centralized exchanges (coming soon)
- **P2P**: Direct peer-to-peer transfers

## 📱 Using Your FTHC Tokens

### Basic Operations

#### Viewing Your Balance
```javascript
// Check your FTHC balance
const balance = await fthcContract.balanceOf(yourAddress);
console.log(`You have ${balance} FTHC tokens`);
```

#### Checking Backing Status
```javascript
// Check if tokens are fully backed
const isFullyBacked = await fthcContract.isFullyBacked();
const backingRatio = await fthcContract.backingRatio();
console.log(`Fully backed: ${isFullyBacked}`);
console.log(`Backing ratio: ${backingRatio / 1e18 * 100}%`);
```

#### Getting USD Value
```javascript
// Get current USD value of your tokens
const goldPrice = await fthcContract.goldPriceUSD();
const usdValue = balance * goldPrice / 1e18;
console.log(`Your tokens are worth $${usdValue} USD`);
```

### Advanced Features

#### Token Transfers
```javascript
// Transfer tokens to another address
await fthcContract.transfer(recipientAddress, amount);
```

#### Token Burning
```javascript
// Burn your tokens (reduces total supply)
await fthcContract.burn(amount);
```

## 🏦 Staking Your FTHC Tokens

Stake your FTHC tokens to earn passive rewards while supporting the network.

### Staking Process

1. **Approve Staking Contract**
```javascript
await fthcContract.approve(stakingAddress, stakeAmount);
```

2. **Stake Your Tokens**
```javascript
await stakingContract.stake(stakeAmount);
```

3. **Earn Rewards**
- Rewards accrue automatically
- Current APY: 5% (adjustable by governance)

4. **Claim Rewards**
```javascript
await stakingContract.claimRewards();
```

5. **Unstake (After Lock Period)**
```javascript
await stakingContract.unstake(amount);
```

### Staking Requirements
- **Minimum Stake**: 1,000 FTHC tokens
- **Lock Period**: 30 days
- **Rewards**: Paid in FTHC tokens
- **Compound**: Reinvest rewards for compound growth

### Staking Benefits
- 🎯 **Passive Income**: Earn rewards without trading
- 🔒 **Network Security**: Support protocol stability
- 📈 **Compound Growth**: Reinvest rewards for higher returns
- 🗳️ **Governance Rights**: Enhanced voting power

## 🗳️ Participating in Governance

Shape the future of FTH Core through decentralized governance.

### Governance Overview
- **Proposal Threshold**: 100,000 FTHC to create proposals
- **Voting Period**: 7 days
- **Quorum**: 10% of total supply
- **Execution Delay**: 2 days after successful vote

### Creating Proposals

```javascript
// Create a governance proposal
await governanceContract.propose(
    "Update Staking APY",
    "Proposal to increase staking APY to 7%",
    targetContract,
    encodedCallData
);
```

### Voting on Proposals

```javascript
// Vote on a proposal (0 = Against, 1 = For, 2 = Abstain)
await governanceContract.vote(proposalId, voteType);
```

### Proposal Types
- **Parameter Updates**: Change staking rates, fees, etc.
- **Contract Upgrades**: Deploy new contract versions
- **Treasury Management**: Manage protocol treasury
- **Emergency Actions**: Handle critical situations

## 📊 Monitoring Your Portfolio

### Key Metrics to Track

#### Token Information
- **Balance**: Your current FTHC holdings
- **USD Value**: Current market value of your holdings
- **Backing Ratio**: How well tokens are backed by gold

#### Staking Information
- **Staked Amount**: Tokens currently staked
- **Pending Rewards**: Unclaimed staking rewards
- **Lock Expiry**: When you can unstake
- **APY**: Current annual percentage yield

#### Governance Participation
- **Voting Power**: Your influence in governance
- **Active Proposals**: Current proposals you can vote on
- **Vote History**: Your past voting record

### Portfolio Dashboard Example

```
┌─────────────────────────────────────────┐
│              FTH Core Portfolio          │
├─────────────────────────────────────────┤
│ FTHC Balance:        5,000 tokens       │
│ USD Value:          $300,000            │
│ Backing Ratio:       120%               │
├─────────────────────────────────────────┤
│ Staked Amount:       3,000 tokens       │
│ Pending Rewards:     25.5 tokens        │
│ Lock Expiry:         15 days            │
│ Staking APY:         5.0%               │
├─────────────────────────────────────────┤
│ Voting Power:        3,000 tokens       │
│ Active Proposals:    2 proposals        │
│ Participation Rate:  85%                │
└─────────────────────────────────────────┘
```

## 🔧 Integration with DeFi

### Supported Platforms

#### Decentralized Exchanges
- **Uniswap**: Deep liquidity pools
- **SushiSwap**: Competitive trading fees
- **Balancer**: Multi-token pools
- **Curve**: Stable swap pools (coming soon)

#### Lending Platforms
- **Aave**: Use FTHC as collateral
- **Compound**: Earn lending interest
- **MakerDAO**: Generate DAI with FTHC

#### Yield Farming
- **Liquidity Mining**: Provide liquidity, earn rewards
- **Yield Strategies**: Automated yield optimization
- **Cross-Protocol**: Multi-platform strategies

### DeFi Strategies

#### Conservative Strategy
1. Stake 70% of tokens for stable 5% APY
2. Hold 30% for liquidity and opportunities
3. Vote on governance proposals

#### Aggressive Strategy
1. Provide liquidity on DEXs for trading fees
2. Use yield farming for higher returns
3. Leverage FTHC as collateral for borrowing

#### Balanced Strategy
1. Stake 50% for baseline returns
2. Provide 30% liquidity for trading fees
3. Keep 20% for active trading

## 🛡️ Security Best Practices

### Wallet Security
- ✅ **Hardware Wallets**: Use Ledger or Trezor for large amounts
- ✅ **Multi-Sig**: Use multi-signature wallets for team funds
- ✅ **Cold Storage**: Keep majority of funds offline
- ❌ **Exchange Storage**: Don't store on exchanges long-term

### Transaction Safety
- ✅ **Double-Check Addresses**: Verify recipient addresses
- ✅ **Gas Prices**: Use appropriate gas prices
- ✅ **Contract Verification**: Only interact with verified contracts
- ❌ **Suspicious Links**: Don't click unknown contract links

### DeFi Risks
- ⚠️ **Smart Contract Risk**: Protocols can have bugs
- ⚠️ **Impermanent Loss**: Liquidity provision risks
- ⚠️ **Rug Pulls**: Only use established protocols
- ⚠️ **Oracle Manipulation**: Price feed risks

## 🚨 Emergency Procedures

### If You Lose Access
1. **Seed Phrase Recovery**: Use your backup seed phrase
2. **Hardware Wallet**: Connect hardware wallet to new interface
3. **Multi-Sig Recovery**: Use other signers for recovery

### If Contract is Paused
1. **Wait for Unpause**: Emergency pauses are temporary
2. **Check Announcements**: Follow official channels
3. **Governance Vote**: Participate in emergency governance

### If You See Suspicious Activity
1. **Report Immediately**: Contact team through official channels
2. **Stop Transactions**: Don't interact with suspicious contracts
3. **Spread Awareness**: Warn community members

## 📈 Advanced Features

### Oracle Price Feeds
- **Real-Time Pricing**: Gold prices updated hourly
- **Multiple Sources**: Redundant oracle providers
- **Price Validation**: Automatic anomaly detection

### Multi-Signature Operations
- **Critical Operations**: Protected by multi-sig
- **Decentralized Control**: No single point of failure
- **Transparent Process**: All operations on-chain

### Emergency Mechanisms
- **Circuit Breakers**: Automatic halts during anomalies
- **Emergency Pause**: Manual halt for critical issues
- **Recovery Procedures**: Clear recovery processes

## 📞 Getting Help

### Official Channels
- **Documentation**: Complete technical docs
- **Discord**: Real-time community support
- **Telegram**: Official announcements
- **Email**: support@fthcore.com

### Community Resources
- **Reddit**: Community discussions
- **Twitter**: News and updates
- **YouTube**: Tutorial videos
- **Medium**: Technical articles

### Developer Resources
- **GitHub**: Open source code
- **API Docs**: Integration documentation
- **SDK**: Development tools
- **Testnet**: Safe testing environment

---

*Welcome to the future of gold-backed cryptocurrency! 🚀*