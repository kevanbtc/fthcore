// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title FTHOracle
 * @dev Oracle contract for gold price feeds
 * Provides reliable gold price data for the FTH Core ecosystem
 */
contract FTHOracle is Ownable, ReentrancyGuard {
    struct PriceData {
        uint256 price; // Price in USD with 8 decimals
        uint256 timestamp;
        bool isValid;
    }
    
    struct Oracle {
        address addr;
        bool isActive;
        uint256 weight; // Weight in basis points (10000 = 100%)
    }
    
    mapping(address => Oracle) public oracles;
    mapping(address => PriceData) public latestPrices;
    address[] public oracleList;
    
    PriceData public aggregatedPrice;
    
    uint256 public constant MAX_PRICE_AGE = 1 hours;
    uint256 public constant MIN_ORACLES = 3;
    uint256 public constant MAX_PRICE_DEVIATION = 500; // 5% max deviation
    uint256 public constant PRICE_PRECISION = 1e8;
    
    uint256 public totalWeight;
    uint256 public updateThreshold = 7500; // 75% of weight needed for update
    
    event OracleAdded(address indexed oracle, uint256 weight);
    event OracleRemoved(address indexed oracle);
    event OracleWeightUpdated(address indexed oracle, uint256 newWeight);
    event PriceUpdated(address indexed oracle, uint256 price, uint256 timestamp);
    event AggregatedPriceUpdated(uint256 price, uint256 timestamp);
    event InvalidPriceSubmitted(address indexed oracle, uint256 price, string reason);
    
    modifier onlyActiveOracle() {
        require(oracles[msg.sender].isActive, "Not an active oracle");
        _;
    }
    
    constructor() Ownable(msg.sender) {}
    
    function addOracle(address oracle, uint256 weight) external onlyOwner {
        require(oracle != address(0), "Invalid oracle address");
        require(weight > 0 && weight <= 10000, "Invalid weight");
        require(!oracles[oracle].isActive, "Oracle already exists");
        
        oracles[oracle] = Oracle({
            addr: oracle,
            isActive: true,
            weight: weight
        });
        
        oracleList.push(oracle);
        totalWeight += weight;
        
        emit OracleAdded(oracle, weight);
    }
    
    function removeOracle(address oracle) external onlyOwner {
        require(oracles[oracle].isActive, "Oracle not active");
        require(oracleList.length > MIN_ORACLES, "Cannot go below minimum oracles");
        
        totalWeight -= oracles[oracle].weight;
        oracles[oracle].isActive = false;
        
        // Remove from array
        for (uint256 i = 0; i < oracleList.length; i++) {
            if (oracleList[i] == oracle) {
                oracleList[i] = oracleList[oracleList.length - 1];
                oracleList.pop();
                break;
            }
        }
        
        emit OracleRemoved(oracle);
    }
    
    function updateOracleWeight(address oracle, uint256 newWeight) external onlyOwner {
        require(oracles[oracle].isActive, "Oracle not active");
        require(newWeight > 0 && newWeight <= 10000, "Invalid weight");
        
        totalWeight = totalWeight - oracles[oracle].weight + newWeight;
        oracles[oracle].weight = newWeight;
        
        emit OracleWeightUpdated(oracle, newWeight);
    }
    
    function submitPrice(uint256 price) external onlyActiveOracle nonReentrant {
        require(price > 0, "Price must be positive");
        
        // Validate price against current aggregated price if available
        if (aggregatedPrice.isValid && aggregatedPrice.timestamp > block.timestamp - MAX_PRICE_AGE) {
            uint256 deviation = price > aggregatedPrice.price 
                ? ((price - aggregatedPrice.price) * 10000) / aggregatedPrice.price
                : ((aggregatedPrice.price - price) * 10000) / aggregatedPrice.price;
            
            if (deviation > MAX_PRICE_DEVIATION) {
                emit InvalidPriceSubmitted(msg.sender, price, "Price deviation too high");
                return;
            }
        }
        
        latestPrices[msg.sender] = PriceData({
            price: price,
            timestamp: block.timestamp,
            isValid: true
        });
        
        emit PriceUpdated(msg.sender, price, block.timestamp);
        
        // Try to update aggregated price
        _updateAggregatedPrice();
    }
    
    function _updateAggregatedPrice() internal {
        uint256 weightedSum = 0;
        uint256 validWeight = 0;
        uint256 validCount = 0;
        
        for (uint256 i = 0; i < oracleList.length; i++) {
            address oracle = oracleList[i];
            if (!oracles[oracle].isActive) continue;
            
            PriceData memory priceData = latestPrices[oracle];
            if (!priceData.isValid || block.timestamp > priceData.timestamp + MAX_PRICE_AGE) {
                continue;
            }
            
            weightedSum += priceData.price * oracles[oracle].weight;
            validWeight += oracles[oracle].weight;
            validCount++;
        }
        
        // Require minimum threshold of oracle weights
        if (validWeight >= (totalWeight * updateThreshold) / 10000 && validCount >= MIN_ORACLES) {
            uint256 newPrice = weightedSum / validWeight;
            
            aggregatedPrice = PriceData({
                price: newPrice,
                timestamp: block.timestamp,
                isValid: true
            });
            
            emit AggregatedPriceUpdated(newPrice, block.timestamp);
        }
    }
    
    function getLatestPrice() external view returns (uint256 price, uint256 timestamp, bool isValid) {
        require(aggregatedPrice.isValid, "No valid price available");
        require(block.timestamp <= aggregatedPrice.timestamp + MAX_PRICE_AGE, "Price too old");
        
        return (aggregatedPrice.price, aggregatedPrice.timestamp, aggregatedPrice.isValid);
    }
    
    function getOraclePrice(address oracle) external view returns (uint256 price, uint256 timestamp, bool isValid) {
        PriceData memory priceData = latestPrices[oracle];
        return (priceData.price, priceData.timestamp, priceData.isValid);
    }
    
    function getOracleInfo(address oracle) external view returns (
        bool isActive,
        uint256 weight,
        uint256 lastPrice,
        uint256 lastUpdate
    ) {
        Oracle memory oracleInfo = oracles[oracle];
        PriceData memory priceData = latestPrices[oracle];
        
        return (
            oracleInfo.isActive,
            oracleInfo.weight,
            priceData.price,
            priceData.timestamp
        );
    }
    
    function getActiveOracles() external view returns (address[] memory) {
        address[] memory activeOracles = new address[](oracleList.length);
        uint256 count = 0;
        
        for (uint256 i = 0; i < oracleList.length; i++) {
            if (oracles[oracleList[i]].isActive) {
                activeOracles[count] = oracleList[i];
                count++;
            }
        }
        
        // Resize array to actual count
        assembly {
            mstore(activeOracles, count)
        }
        
        return activeOracles;
    }
    
    function setUpdateThreshold(uint256 newThreshold) external onlyOwner {
        require(newThreshold >= 5000 && newThreshold <= 10000, "Invalid threshold");
        updateThreshold = newThreshold;
    }
    
    function emergencySetPrice(uint256 price) external onlyOwner {
        require(price > 0, "Price must be positive");
        
        aggregatedPrice = PriceData({
            price: price,
            timestamp: block.timestamp,
            isValid: true
        });
        
        emit AggregatedPriceUpdated(price, block.timestamp);
    }
    
    function isPriceStale() external view returns (bool) {
        return !aggregatedPrice.isValid || block.timestamp > aggregatedPrice.timestamp + MAX_PRICE_AGE;
    }
}