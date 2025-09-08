# FTH Core - Simple Gold-Backed Token

A minimal, transparent gold tokenization system with 1:1 backing guarantees.

## 🎯 Core Concept

- **1 FTHC token = 1 gram of physical gold**
- **Simple mint/burn mechanics**
- **Transparent gold reserve tracking**
- **Owner-controlled operations**

## ✨ Key Features

- **Full Backing Guarantee**: Cannot mint tokens without sufficient gold reserves
- **Real-time Backing Ratio**: View current backing percentage at any time
- **Authorized Operations**: Owner can delegate gold/mint operations to trusted parties
- **Transparent Reserves**: All gold deposits/withdrawals are tracked on-chain

## 🏗 Contract Architecture

```solidity
contract FTHCore is ERC20, Ownable {
    uint256 public goldReserves;  // Total gold backing in grams
    mapping(address => bool) public authorized;  // Authorized operators
    
    // Core functions
    function depositGold(uint256 grams) external onlyAuthorized;
    function withdrawGold(uint256 grams) external onlyAuthorized;
    function mint(address to, uint256 amount) external onlyAuthorized;
    function burn(uint256 amount) external;
}
```

## 🚀 Quick Start

### Installation

```bash
git clone https://github.com/kevanbtc/fthcore.git
cd fthcore
forge install
```

### Build & Test

```bash
forge build
forge test -vv
```

### Deploy

```bash
forge script script/Deploy.s.sol --rpc-url $RPC_URL --broadcast
```

## 📊 Usage Examples

### Check Backing Status
```solidity
uint256 ratio = token.backingRatio();  // Returns ratio in 1e18 format (2e18 = 200%)
bool backed = token.isFullyBacked();   // Returns true if reserves >= supply
```

### Deposit Gold & Mint Tokens
```solidity
// 1. Deposit 1000 grams of gold
token.depositGold(1000e18);

// 2. Mint 500 FTHC tokens (leaves 500g buffer)
token.mint(user, 500e18);

// Result: 200% backing ratio
```

### Burn & Withdraw
```solidity
// 1. User burns their tokens
token.burn(250e18);

// 2. Withdraw corresponding gold
token.withdrawGold(250e18);

// Result: Maintains 1:1 backing
```

## 🔐 Security Model

### Access Control
- **Owner**: Can set authorized operators, transfer ownership
- **Authorized**: Can deposit/withdraw gold, mint tokens
- **Users**: Can burn their own tokens, transfer freely

### Safety Mechanisms
- **Backing Enforcement**: Cannot mint without sufficient gold reserves
- **Withdrawal Limits**: Cannot withdraw gold if it would break 1:1 backing
- **Transparent Events**: All operations emit detailed events

## 📈 Gas Costs (Optimized)

| Operation | Gas Cost |
|-----------|----------|
| Deposit Gold | ~38,000 |
| Mint Tokens | ~95,000 |
| Burn Tokens | ~99,000 |
| Withdraw Gold | ~96,000 |
| Check Backing | ~2,500 |

## 🧪 Test Coverage

- ✅ Initial state validation
- ✅ Gold deposit/withdrawal mechanics  
- ✅ Token minting with backing enforcement
- ✅ Burning mechanisms
- ✅ Backing ratio calculations
- ✅ Authorization system
- ✅ Edge case handling

**10/10 tests passing** with comprehensive coverage.

## 🏆 Why FTH Core?

### Simplicity First
- **90 lines of core logic** vs 1000+ in complex systems
- **Single contract** with minimal dependencies
- **Clear, auditable code** with straightforward mechanics

### Maximum Transparency  
- **Real-time reserves** visible on-chain
- **Simple backing math** anyone can verify
- **No complex oracle dependencies** or pricing mechanisms

### Production Ready
- **OpenZeppelin standards** for security
- **Comprehensive test suite** covering all scenarios  
- **Gas optimized** for cost-effective operations

## 📄 License

MIT License - see [LICENSE](LICENSE) file.

---

**Built for transparency, security, and simplicity in gold tokenization.**
