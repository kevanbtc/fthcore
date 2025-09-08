// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FTHCore is ERC20, Ownable {
    uint256 public constant GOLD_BACKING_RATIO = 1e18; // 1 token = 1 gram of gold
    uint256 public goldReserves; // Total gold backing in grams
    
    mapping(address => bool) public authorized;
    
    event GoldDeposited(uint256 amount);
    event GoldWithdrawn(uint256 amount);
    event TokensMinted(address indexed to, uint256 amount);
    event TokensBurned(address indexed from, uint256 amount);
    
    modifier onlyAuthorized() {
        require(authorized[msg.sender] || msg.sender == owner(), "Not authorized");
        _;
    }
    
    constructor() ERC20("FTH Core Gold", "FTHC") Ownable(msg.sender) {
        authorized[msg.sender] = true;
    }
    
    function setAuthorized(address account, bool status) external onlyOwner {
        authorized[account] = status;
    }
    
    function depositGold(uint256 grams) external onlyAuthorized {
        goldReserves += grams;
        emit GoldDeposited(grams);
    }
    
    function withdrawGold(uint256 grams) external onlyAuthorized {
        require(goldReserves >= grams, "Insufficient gold reserves");
        require(goldReserves - grams >= totalSupply(), "Would break backing ratio");
        
        goldReserves -= grams;
        emit GoldWithdrawn(grams);
    }
    
    function mint(address to, uint256 amount) external onlyAuthorized {
        require(goldReserves >= totalSupply() + amount, "Insufficient gold backing");
        _mint(to, amount);
        emit TokensMinted(to, amount);
    }
    
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
        emit TokensBurned(msg.sender, amount);
    }
    
    function burnFrom(address from, uint256 amount) external onlyAuthorized {
        _burn(from, amount);
        emit TokensBurned(from, amount);
    }
    
    function backingRatio() external view returns (uint256) {
        if (totalSupply() == 0) return type(uint256).max;
        return (goldReserves * 1e18) / totalSupply();
    }
    
    function isFullyBacked() external view returns (bool) {
        return goldReserves >= totalSupply();
    }
}