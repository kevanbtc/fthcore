# FTH Core - Enhanced Gold-Backed Token System

## 🏗 Architecture Overview

FTH Core is a comprehensive gold-backed token ecosystem featuring multiple smart contracts working together to provide a secure, transparent, and decentralized gold tokenization platform.

### Core Components

```mermaid
graph TB
    subgraph "Core Contracts"
        FTC[FTHCore Token]
        GOV[FTHGovernance]
        STK[FTHStaking]
        ORA[FTHOracle]
        MSI[FTHMultiSig]
    end
    
    subgraph "External Systems"
        GLD[Physical Gold]
        URS[Users]
        VAL[Gold Validators]
        ORP[Oracle Providers]
    end
    
    FTC --> GOV
    FTC --> STK
    FTC --> ORA
    MSI --> FTC
    MSI --> GOV
    
    GLD --> FTC
    URS --> FTC
    URS --> STK
    URS --> GOV
    VAL --> FTC
    ORP --> ORA
    ORA --> FTC
```

## 📊 Token Lifecycle Flow

```mermaid
sequenceDiagram
    participant U as User
    participant V as Validator
    participant FTC as FTHCore
    participant G as Gold Reserve
    participant O as Oracle
    
    Note over V,G: Gold Deposit Process
    V->>G: Deposit Physical Gold
    V->>FTC: depositGold(amount)
    FTC->>FTC: Update goldReserves
    FTC->>FTC: Emit GoldDeposited
    
    Note over U,FTC: Token Minting
    V->>FTC: mint(user, amount)
    FTC->>FTC: Check goldReserves >= totalSupply + amount
    FTC->>U: Mint FTHC tokens
    FTC->>FTC: Emit TokensMinted
    
    Note over O,FTC: Price Updates
    O->>FTC: updateGoldPrice(price)
    FTC->>FTC: Update goldPriceUSD
    FTC->>FTC: Emit GoldPriceUpdated
    
    Note over U,FTC: Token Operations
    U->>FTC: transfer/burn tokens
    FTC->>FTC: Execute operation
    
    Note over V,FTC: Gold Withdrawal
    V->>FTC: withdrawGold(amount)
    FTC->>FTC: Check backing ratio maintained
    FTC->>G: Release physical gold
    FTC->>FTC: Update goldReserves
```

## 🏛 Governance Flow

```mermaid
stateDiagram-v2
    [*] --> ProposalCreation
    ProposalCreation --> Active: proposal submitted
    
    Active --> Voting: voting period starts
    Voting --> VotingActive: users vote
    VotingActive --> VotingActive: more votes
    VotingActive --> VotingEnded: voting period ends
    
    VotingEnded --> Succeeded: quorum met & majority for
    VotingEnded --> Defeated: quorum not met or majority against
    
    Succeeded --> ExecutionDelay: 2 day delay
    ExecutionDelay --> Executed: proposal executed
    
    Active --> Cancelled: proposer/owner cancels
    Defeated --> [*]
    Executed --> [*]
    Cancelled --> [*]
```

## 🥇 Staking Mechanism

```mermaid
graph LR
    subgraph "Staking Process"
        A[User Stakes FTHC] --> B[Lock Period Starts]
        B --> C[Earn Rewards]
        C --> D[Claim Rewards]
        D --> C
        C --> E[Unstake After Lock]
        E --> F[Receive FTHC + Rewards]
    end
    
    subgraph "Reward Calculation"
        G[Staked Amount] --> H[× APY Rate]
        H --> I[× Time Staked]
        I --> J[÷ Seconds Per Year]
        J --> K[= Reward Amount]
    end
```

## 🔒 Security Architecture

```mermaid
graph TB
    subgraph "Security Layers"
        A[Access Control]
        B[Rate Limiting]
        C[Emergency Pause]
        D[Multi-Sig Operations]
        E[Reentrancy Guards]
        F[Oracle Validation]
    end
    
    subgraph "Authorization Levels"
        G[Owner]
        H[Authorized Operators]
        I[Regular Users]
    end
    
    G --> A
    H --> A
    I --> A
    
    A --> B
    B --> C
    C --> D
    D --> E
    E --> F
```

## 🌐 Oracle System

```mermaid
graph TB
    subgraph "Oracle Network"
        O1[Oracle 1 - Weight 30%]
        O2[Oracle 2 - Weight 25%]
        O3[Oracle 3 - Weight 25%]
        O4[Oracle 4 - Weight 20%]
    end
    
    subgraph "Price Aggregation"
        AGG[Weighted Average]
        VAL[Validation Logic]
        OUT[Final Price]
    end
    
    O1 --> AGG
    O2 --> AGG
    O3 --> AGG
    O4 --> AGG
    
    AGG --> VAL
    VAL --> OUT
    OUT --> FTHCore[FTH Core Contract]
```

## 🛡 Multi-Signature Operations

```mermaid
sequenceDiagram
    participant O1 as Owner 1
    participant O2 as Owner 2
    participant O3 as Owner 3
    participant MS as MultiSig
    participant TC as Target Contract
    
    O1->>MS: submitTransaction(target, data)
    MS->>MS: Create transaction ID
    O1->>MS: confirmTransaction(id)
    MS->>MS: Add confirmation (1/3)
    
    O2->>MS: confirmTransaction(id)
    MS->>MS: Add confirmation (2/3)
    
    O3->>MS: confirmTransaction(id)
    MS->>MS: Add confirmation (3/3)
    MS->>MS: Check if threshold met
    MS->>TC: Execute transaction
    TC->>TC: Perform action
    TC-->>MS: Success/Failure
    MS->>MS: Emit Execution event
```

## 📈 Token Economics

### Backing Mechanism
- **1:1 Gold Backing**: Each FTHC token represents 1 gram of physical gold
- **Full Reserves**: Cannot mint tokens without sufficient gold backing
- **Transparent Tracking**: All gold deposits/withdrawals recorded on-chain

### Supply Mechanics
- **Maximum Supply**: 1 billion FTHC tokens
- **Minting**: Only possible with sufficient gold reserves
- **Burning**: Available to any token holder at any time

### Price Discovery
- **Oracle-Fed Pricing**: Real-time gold price updates from multiple sources
- **USD Valuation**: Each token's USD value matches gold price per gram
- **Market Trading**: Tokens can trade on secondary markets

## 🔧 Technical Specifications

### Smart Contract Details

#### FTHCore Contract
- **Token Standard**: ERC20 with extensions
- **Security Features**: Pausable, ReentrancyGuard, Access Control
- **Gas Optimization**: Efficient storage patterns
- **Event Logging**: Comprehensive event emissions

#### FTHGovernance Contract
- **Voting Period**: 7 days
- **Proposal Threshold**: 100,000 FTHC tokens
- **Quorum Requirement**: 10% of total supply
- **Execution Delay**: 2 days after successful vote

#### FTHStaking Contract
- **Minimum Stake**: 1,000 FTHC tokens
- **Lock Period**: 30 days
- **Default APY**: 5% (configurable)
- **Reward Distribution**: Continuous, claimable anytime

#### FTHOracle Contract
- **Minimum Oracles**: 3 active oracles required
- **Price Validation**: ±5% deviation check
- **Update Threshold**: 75% oracle weight consensus
- **Data Freshness**: 1-hour maximum age

### Gas Costs (Optimized)

| Operation | Gas Cost | Description |
|-----------|----------|-------------|
| Deposit Gold | ~45,000 | Including events and security checks |
| Mint Tokens | ~110,000 | Including backing verification |
| Burn Tokens | ~105,000 | Including event emissions |
| Withdraw Gold | ~105,000 | Including backing ratio checks |
| Stake Tokens | ~120,000 | Including reward calculations |
| Vote on Proposal | ~95,000 | Including weight calculations |
| Oracle Price Update | ~85,000 | Including aggregation logic |

## 🚀 Deployment Guide

### Prerequisites
- Foundry development framework
- Ethereum node access (Infura/Alchemy)
- Sufficient ETH for deployment gas costs

### Deployment Steps

1. **Deploy Core Contracts**
```bash
forge script script/Deploy.s.sol --rpc-url $RPC_URL --broadcast
```

2. **Initialize Oracle System**
```solidity
oracle.addOracle(oracle1Address, 3000); // 30% weight
oracle.addOracle(oracle2Address, 2500); // 25% weight
oracle.addOracle(oracle3Address, 2500); // 25% weight
oracle.addOracle(oracle4Address, 2000); // 20% weight
```

3. **Set Up Multi-Sig**
```solidity
address[] memory owners = [owner1, owner2, owner3];
FTHMultiSig multiSig = new FTHMultiSig(owners, 2); // 2 of 3 required
```

4. **Configure Governance**
```solidity
FTHGovernance governance = new FTHGovernance(address(fthCore));
```

### Network Configuration

#### Mainnet Deployment
- Gas Price: Use EIP-1559 with appropriate tips
- Verification: Verify all contracts on Etherscan
- Security: Use hardware wallets for deployment

#### Testnet Deployment
- Networks: Goerli, Sepolia supported
- Faucets: Obtain test ETH from official faucets
- Testing: Full integration testing recommended

## 🔐 Security Considerations

### Access Control
- **Owner Privileges**: Can pause contracts, update parameters
- **Authorized Operators**: Can handle gold operations and minting
- **Multi-Sig Protection**: Critical operations require multiple signatures

### Emergency Procedures
- **Emergency Pause**: Immediate halt of all operations
- **Emergency Mode**: Owner-only operations during crisis
- **Circuit Breakers**: Automatic halts on anomalous conditions

### Audit Recommendations
- **External Audit**: Professional security audit recommended
- **Bug Bounty**: Consider implementing bug bounty program
- **Monitoring**: Continuous monitoring of contract interactions

## 📚 Integration Examples

### Frontend Integration
```javascript
// Connect to FTH Core contract
const fthCore = new ethers.Contract(address, abi, provider);

// Check user's balance and backing ratio
const balance = await fthCore.balanceOf(userAddress);
const backingRatio = await fthCore.backingRatio();
const fullyBacked = await fthCore.isFullyBacked();

// Display USD value
const goldPrice = await fthCore.goldPriceUSD();
const usdValue = balance.mul(goldPrice).div(ethers.utils.parseEther("1"));
```

### Web3 Integration
```javascript
// Stake tokens
const stakingContract = new ethers.Contract(stakingAddress, stakingAbi, signer);
await fthCore.approve(stakingAddress, stakeAmount);
await stakingContract.stake(stakeAmount);

// Vote on proposal
const governanceContract = new ethers.Contract(govAddress, govAbi, signer);
await governanceContract.vote(proposalId, voteType);
```

## 🎯 Future Enhancements

### Planned Features
- **Cross-Chain Bridge**: Deploy on multiple chains
- **NFT Certificates**: Physical gold backing certificates
- **Insurance Integration**: Protocol insurance mechanisms
- **Mobile App**: Native mobile application
- **DeFi Integration**: Yield farming and liquidity mining

### Roadmap
- **Q1 2024**: Enhanced oracle network
- **Q2 2024**: Cross-chain deployment
- **Q3 2024**: Mobile application
- **Q4 2024**: DeFi protocol integrations

## 📞 Support & Community

### Documentation
- **Technical Docs**: Detailed API documentation
- **User Guides**: Step-by-step user instructions
- **Developer Resources**: Integration examples and SDKs

### Community Channels
- **Discord**: Real-time community support
- **Telegram**: Official announcements
- **GitHub**: Technical discussions and issues
- **Twitter**: News and updates

---

*Built for transparency, security, and simplicity in gold tokenization.*