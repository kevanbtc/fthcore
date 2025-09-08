// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract FTHCore is ERC20, Ownable, Pausable, ReentrancyGuard {
    uint256 public constant GOLD_BACKING_RATIO = 1e18; // 1 token = 1 gram of gold
    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 1e18; // 1 billion tokens max
    uint256 public goldReserves; // Total gold backing in grams
    uint256 public goldPriceUSD; // Gold price in USD per gram (with 1e8 precision)
    
    mapping(address => bool) public authorized;
    mapping(address => uint256) public lastOperation; // Rate limiting
    
    uint256 public operationCooldown = 1 hours; // Cooldown between operations
    bool public emergencyMode = false;
    
    event GoldDeposited(address indexed operator, uint256 amount, uint256 timestamp);
    event GoldWithdrawn(address indexed operator, uint256 amount, uint256 timestamp);
    event TokensMinted(address indexed to, uint256 amount, address indexed operator);
    event TokensBurned(address indexed from, uint256 amount);
    event AuthorizationChanged(address indexed account, bool status);
    event GoldPriceUpdated(uint256 newPrice, uint256 timestamp);
    event EmergencyModeToggled(bool enabled);
    event CooldownUpdated(uint256 newCooldown);
    
    modifier onlyAuthorized() {
        require(authorized[msg.sender] || msg.sender == owner(), "Not authorized");
        require(!emergencyMode || msg.sender == owner(), "Emergency mode: owner only");
        _;
    }
    
    modifier rateLimited() {
        require(
            block.timestamp >= lastOperation[msg.sender] + operationCooldown || 
            msg.sender == owner(), 
            "Operation too frequent"
        );
        lastOperation[msg.sender] = block.timestamp;
        _;
    }
    
    constructor() ERC20("FTH Core Gold", "FTHC") Ownable(msg.sender) {
        authorized[msg.sender] = true;
        goldPriceUSD = 60 * 1e8; // ~$60 per gram initial price
    }
    
    // === EMERGENCY FUNCTIONS ===
    
    function toggleEmergencyMode() external onlyOwner {
        emergencyMode = !emergencyMode;
        if (emergencyMode) {
            _pause();
        } else {
            _unpause();
        }
        emit EmergencyModeToggled(emergencyMode);
    }
    
    function emergencyPause() external onlyOwner {
        _pause();
    }
    
    function emergencyUnpause() external onlyOwner {
        _unpause();
    }
    
    // === AUTHORIZATION FUNCTIONS ===
    
    function setAuthorized(address account, bool status) external onlyOwner {
        authorized[account] = status;
        emit AuthorizationChanged(account, status);
    }
    
    function setOperationCooldown(uint256 newCooldown) external onlyOwner {
        require(newCooldown <= 24 hours, "Cooldown too long");
        operationCooldown = newCooldown;
        emit CooldownUpdated(newCooldown);
    }
    
    // === GOLD OPERATIONS ===
    
    function depositGold(uint256 grams) external onlyAuthorized rateLimited whenNotPaused nonReentrant {
        require(grams > 0, "Amount must be positive");
        goldReserves += grams;
        emit GoldDeposited(msg.sender, grams, block.timestamp);
    }
    
    function withdrawGold(uint256 grams) external onlyAuthorized rateLimited whenNotPaused nonReentrant {
        require(grams > 0, "Amount must be positive");
        require(goldReserves >= grams, "Insufficient gold reserves");
        require(goldReserves - grams >= totalSupply(), "Would break backing ratio");
        
        goldReserves -= grams;
        emit GoldWithdrawn(msg.sender, grams, block.timestamp);
    }
    
    // === TOKEN OPERATIONS ===
    
    function mint(address to, uint256 amount) external onlyAuthorized rateLimited whenNotPaused nonReentrant {
        require(to != address(0), "Cannot mint to zero address");
        require(amount > 0, "Amount must be positive");
        require(totalSupply() + amount <= MAX_SUPPLY, "Would exceed max supply");
        require(goldReserves >= totalSupply() + amount, "Insufficient gold backing");
        
        _mint(to, amount);
        emit TokensMinted(to, amount, msg.sender);
    }
    
    function burn(uint256 amount) external whenNotPaused {
        require(amount > 0, "Amount must be positive");
        _burn(msg.sender, amount);
        emit TokensBurned(msg.sender, amount);
    }
    
    function burnFrom(address from, uint256 amount) external onlyAuthorized whenNotPaused {
        require(amount > 0, "Amount must be positive");
        _burn(from, amount);
        emit TokensBurned(from, amount);
    }
    
    // === ORACLE FUNCTIONS ===
    
    function updateGoldPrice(uint256 newPriceUSD) external onlyAuthorized {
        require(newPriceUSD > 0, "Price must be positive");
        require(newPriceUSD <= 1000 * 1e8, "Price too high"); // Max $1000/gram sanity check
        goldPriceUSD = newPriceUSD;
        emit GoldPriceUpdated(newPriceUSD, block.timestamp);
    }
    
    // === VIEW FUNCTIONS ===
    
    function backingRatio() external view returns (uint256) {
        if (totalSupply() == 0) return type(uint256).max;
        return (goldReserves * 1e18) / totalSupply();
    }
    
    function isFullyBacked() external view returns (bool) {
        return goldReserves >= totalSupply();
    }
    
    function getTokenValueUSD() external view returns (uint256) {
        return goldPriceUSD; // Returns USD value per token (same as gold price per gram)
    }
    
    function getTotalValueUSD() external view returns (uint256) {
        return (totalSupply() * goldPriceUSD) / 1e18;
    }
    
    function getReservesValueUSD() external view returns (uint256) {
        return (goldReserves * goldPriceUSD) / 1e18;
    }
    
    function getMaxMintable() external view returns (uint256) {
        if (goldReserves <= totalSupply()) return 0;
        uint256 maxFromReserves = goldReserves - totalSupply();
        uint256 maxFromSupply = MAX_SUPPLY - totalSupply();
        return maxFromReserves < maxFromSupply ? maxFromReserves : maxFromSupply;
    }
    
    function getOperationCooldownRemaining(address account) external view returns (uint256) {
        uint256 nextAllowed = lastOperation[account] + operationCooldown;
        if (block.timestamp >= nextAllowed) return 0;
        return nextAllowed - block.timestamp;
    }
    
    // === OVERRIDE FUNCTIONS ===
    
    function transfer(address to, uint256 amount) public override whenNotPaused returns (bool) {
        return super.transfer(to, amount);
    }
    
    function transferFrom(address from, address to, uint256 amount) public override whenNotPaused returns (bool) {
        return super.transferFrom(from, to, amount);
    }
}