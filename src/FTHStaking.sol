// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "./FTHCore.sol";

/**
 * @title FTHStaking
 * @dev Staking contract for FTH Core tokens
 * Users can stake FTHC tokens to earn rewards
 */
contract FTHStaking is Ownable, ReentrancyGuard, Pausable {
    FTHCore public immutable fthCore;
    
    struct StakeInfo {
        uint256 amount;
        uint256 startTime;
        uint256 lastRewardTime;
        uint256 rewardDebt;
    }
    
    mapping(address => StakeInfo) public stakes;
    
    uint256 public totalStaked;
    uint256 public rewardRate = 500; // 5% APY (500 basis points)
    uint256 public constant RATE_PRECISION = 10000;
    uint256 public constant SECONDS_PER_YEAR = 365 days;
    
    uint256 public minimumStake = 1000 * 1e18; // 1000 FTHC minimum
    uint256 public lockPeriod = 30 days; // 30 day lock period
    
    uint256 public rewardPool; // Available rewards
    
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 amount);
    event RewardRateUpdated(uint256 newRate);
    event RewardPoolFunded(uint256 amount);
    
    constructor(address _fthCore) Ownable(msg.sender) {
        fthCore = FTHCore(_fthCore);
    }
    
    function stake(uint256 amount) external whenNotPaused nonReentrant {
        require(amount >= minimumStake, "Amount below minimum stake");
        require(fthCore.balanceOf(msg.sender) >= amount, "Insufficient balance");
        
        StakeInfo storage userStake = stakes[msg.sender];
        
        // Claim any pending rewards first
        if (userStake.amount > 0) {
            _claimRewards(msg.sender);
        }
        
        // Transfer tokens to this contract
        require(fthCore.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        
        // Update stake info
        userStake.amount += amount;
        userStake.startTime = block.timestamp;
        userStake.lastRewardTime = block.timestamp;
        
        totalStaked += amount;
        
        emit Staked(msg.sender, amount);
    }
    
    function unstake(uint256 amount) external nonReentrant {
        StakeInfo storage userStake = stakes[msg.sender];
        require(userStake.amount >= amount, "Insufficient staked amount");
        require(
            block.timestamp >= userStake.startTime + lockPeriod,
            "Lock period not expired"
        );
        
        // Claim rewards first
        _claimRewards(msg.sender);
        
        // Update stake info
        userStake.amount -= amount;
        if (userStake.amount == 0) {
            userStake.startTime = 0;
            userStake.lastRewardTime = 0;
        }
        
        totalStaked -= amount;
        
        // Transfer tokens back to user
        require(fthCore.transfer(msg.sender, amount), "Transfer failed");
        
        emit Unstaked(msg.sender, amount);
    }
    
    function claimRewards() external nonReentrant {
        _claimRewards(msg.sender);
    }
    
    function _claimRewards(address user) internal {
        StakeInfo storage userStake = stakes[user];
        if (userStake.amount == 0) return;
        
        uint256 rewards = calculateRewards(user);
        if (rewards == 0) return;
        
        require(rewardPool >= rewards, "Insufficient reward pool");
        
        userStake.lastRewardTime = block.timestamp;
        rewardPool -= rewards;
        
        require(fthCore.transfer(user, rewards), "Reward transfer failed");
        
        emit RewardClaimed(user, rewards);
    }
    
    function calculateRewards(address user) public view returns (uint256) {
        StakeInfo storage userStake = stakes[user];
        if (userStake.amount == 0) return 0;
        
        uint256 timeStaked = block.timestamp - userStake.lastRewardTime;
        uint256 annualReward = (userStake.amount * rewardRate) / RATE_PRECISION;
        uint256 reward = (annualReward * timeStaked) / SECONDS_PER_YEAR;
        
        return reward;
    }
    
    function fundRewardPool(uint256 amount) external {
        require(fthCore.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        rewardPool += amount;
        emit RewardPoolFunded(amount);
    }
    
    function setRewardRate(uint256 newRate) external onlyOwner {
        require(newRate <= 2000, "Rate too high"); // Max 20% APY
        rewardRate = newRate;
        emit RewardRateUpdated(newRate);
    }
    
    function setMinimumStake(uint256 newMinimum) external onlyOwner {
        minimumStake = newMinimum;
    }
    
    function setLockPeriod(uint256 newPeriod) external onlyOwner {
        require(newPeriod <= 365 days, "Lock period too long");
        lockPeriod = newPeriod;
    }
    
    function emergencyWithdraw() external onlyOwner {
        uint256 balance = fthCore.balanceOf(address(this));
        require(fthCore.transfer(owner(), balance), "Emergency withdraw failed");
    }
    
    function pause() external onlyOwner {
        _pause();
    }
    
    function unpause() external onlyOwner {
        _unpause();
    }
    
    function getStakeInfo(address user) external view returns (
        uint256 amount,
        uint256 startTime,
        uint256 lockExpiryTime,
        uint256 pendingRewards
    ) {
        StakeInfo storage userStake = stakes[user];
        return (
            userStake.amount,
            userStake.startTime,
            userStake.startTime + lockPeriod,
            calculateRewards(user)
        );
    }
    
    function getAPY() external view returns (uint256) {
        return rewardRate; // Returns in basis points (500 = 5%)
    }
}