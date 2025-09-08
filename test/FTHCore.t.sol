// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/FTHCore.sol";

contract FTHCoreTest is Test {
    FTHCore public token;
    address public owner = address(0x123);
    address public user = address(0x456);
    address public operator = address(0x789);
    
    function setUp() public {
        vm.startPrank(owner);
        token = new FTHCore();
        token.setAuthorized(operator, true);
        vm.stopPrank();
    }
    
    function testInitialState() public view {
        assertEq(token.name(), "FTH Core Gold");
        assertEq(token.symbol(), "FTHC");
        assertEq(token.goldReserves(), 0);
        assertEq(token.totalSupply(), 0);
        assertEq(token.goldPriceUSD(), 60 * 1e8); // Initial price
        assertTrue(token.authorized(owner));
        assertTrue(token.isFullyBacked());
        assertFalse(token.emergencyMode());
        assertFalse(token.paused());
    }
    
    function testDepositGold() public {
        vm.prank(operator);
        token.depositGold(100e18);
        
        assertEq(token.goldReserves(), 100e18);
    }
    
    function testDepositGoldRateLimit() public {
        vm.startPrank(operator);
        token.depositGold(100e18);
        
        // Second operation should fail due to rate limit
        vm.expectRevert("Operation too frequent");
        token.depositGold(50e18);
        vm.stopPrank();
    }
    
    function testMintWithBacking() public {
        vm.startPrank(operator);
        token.depositGold(100e18);
        
        // Wait for rate limit
        vm.warp(block.timestamp + 2 hours);
        
        token.mint(user, 50e18);
        vm.stopPrank();
        
        assertEq(token.balanceOf(user), 50e18);
        assertEq(token.totalSupply(), 50e18);
        assertTrue(token.isFullyBacked());
        assertEq(token.backingRatio(), 2e18); // 200% backing
    }
    
    function testMintWithoutBacking() public {
        vm.startPrank(operator);
        vm.expectRevert("Insufficient gold backing");
        token.mint(user, 50e18);
        vm.stopPrank();
    }
    
    function testMaxSupplyLimit() public {
        vm.startPrank(operator);
        token.depositGold(token.MAX_SUPPLY() + 1e18);
        
        vm.expectRevert("Would exceed max supply");
        token.mint(user, token.MAX_SUPPLY() + 1);
        vm.stopPrank();
    }
    
    function testBurn() public {
        vm.startPrank(operator);
        token.depositGold(100e18);
        
        vm.warp(block.timestamp + 2 hours);
        token.mint(user, 50e18);
        vm.stopPrank();
        
        vm.prank(user);
        token.burn(25e18);
        
        assertEq(token.balanceOf(user), 25e18);
        assertEq(token.totalSupply(), 25e18);
    }
    
    function testWithdrawGold() public {
        vm.startPrank(operator);
        token.depositGold(100e18);
        
        vm.warp(block.timestamp + 2 hours);
        token.mint(user, 50e18);
        
        vm.warp(block.timestamp + 2 hours);
        token.withdrawGold(25e18);
        vm.stopPrank();
        
        assertEq(token.goldReserves(), 75e18);
        assertTrue(token.isFullyBacked());
    }
    
    function testWithdrawTooMuchGold() public {
        vm.startPrank(operator);
        token.depositGold(100e18);
        
        vm.warp(block.timestamp + 2 hours);
        token.mint(user, 50e18);
        
        vm.warp(block.timestamp + 2 hours);
        vm.expectRevert("Would break backing ratio");
        token.withdrawGold(60e18);
        vm.stopPrank();
    }
    
    function testBackingRatio() public {
        vm.startPrank(operator);
        token.depositGold(100e18);
        
        vm.warp(block.timestamp + 2 hours);
        token.mint(user, 50e18);
        vm.stopPrank();
        
        assertEq(token.backingRatio(), 2e18); // 200% backing ratio
    }
    
    function testAuthorization() public {
        vm.prank(owner);
        token.setAuthorized(user, true);
        
        assertTrue(token.authorized(user));
        
        vm.prank(user);
        token.depositGold(50e18);
        
        assertEq(token.goldReserves(), 50e18);
    }
    
    function testUnauthorizedActions() public {
        vm.startPrank(user);
        vm.expectRevert("Not authorized");
        token.depositGold(50e18);
        
        vm.expectRevert("Not authorized");
        token.mint(user, 25e18);
        
        vm.expectRevert("Not authorized");
        token.updateGoldPrice(65e8);
        vm.stopPrank();
    }
    
    function testEmergencyMode() public {
        // Mint some tokens first
        vm.startPrank(operator);
        token.depositGold(100e18);
        
        vm.warp(block.timestamp + 2 hours);
        token.mint(user, 50e18);
        vm.stopPrank();
        
        // Activate emergency mode
        vm.prank(owner);
        token.toggleEmergencyMode();
        
        assertTrue(token.emergencyMode());
        assertTrue(token.paused());
        
        // Operations should be restricted to owner
        vm.expectRevert("Emergency mode: owner only");
        vm.prank(operator);
        token.depositGold(50e18);
        
        // Transfers should be paused
        vm.expectRevert();
        vm.prank(user);
        token.transfer(operator, 25e18);
    }
    
    function testPauseUnpause() public {
        vm.startPrank(owner);
        token.emergencyPause();
        assertTrue(token.paused());
        
        token.emergencyUnpause();
        assertFalse(token.paused());
        vm.stopPrank();
    }
    
    function testGoldPriceUpdate() public {
        vm.prank(operator);
        token.updateGoldPrice(65e8);
        
        assertEq(token.goldPriceUSD(), 65e8);
    }
    
    function testInvalidGoldPrice() public {
        vm.startPrank(operator);
        vm.expectRevert("Price must be positive");
        token.updateGoldPrice(0);
        
        vm.expectRevert("Price too high");
        token.updateGoldPrice(1001e8);
        vm.stopPrank();
    }
    
    function testViewFunctions() public {
        vm.startPrank(operator);
        token.depositGold(200e18);
        token.updateGoldPrice(65e8);
        
        vm.warp(block.timestamp + 2 hours);
        token.mint(user, 100e18);
        vm.stopPrank();
        
        // Test various view functions
        assertEq(token.getTokenValueUSD(), 65e8);
        assertEq(token.getTotalValueUSD(), 100e18 * 65e8 / 1e18);
        assertEq(token.getReservesValueUSD(), 200e18 * 65e8 / 1e18);
        assertEq(token.getMaxMintable(), 100e18); // 200 reserves - 100 supply
    }
    
    function testOperationCooldown() public {
        vm.prank(owner);
        token.setOperationCooldown(2 hours);
        
        vm.startPrank(operator);
        token.depositGold(100e18);
        
        // Check cooldown
        uint256 remaining = token.getOperationCooldownRemaining(operator);
        assertEq(remaining, 2 hours);
        
        // Fast forward half way
        vm.warp(block.timestamp + 1 hours);
        remaining = token.getOperationCooldownRemaining(operator);
        assertEq(remaining, 1 hours);
        
        // Fast forward past cooldown
        vm.warp(block.timestamp + 2 hours);
        remaining = token.getOperationCooldownRemaining(operator);
        assertEq(remaining, 0);
        
        // Should be able to operate again
        token.depositGold(50e18);
        assertEq(token.goldReserves(), 150e18);
        vm.stopPrank();
    }
    
    function testBurnFrom() public {
        vm.startPrank(operator);
        token.depositGold(100e18);
        
        vm.warp(block.timestamp + 2 hours);
        token.mint(user, 50e18);
        
        vm.warp(block.timestamp + 2 hours);
        token.burnFrom(user, 25e18);
        vm.stopPrank();
        
        assertEq(token.balanceOf(user), 25e18);
        assertEq(token.totalSupply(), 25e18);
    }
    
    function testZeroAmountValidation() public {
        vm.startPrank(operator);
        vm.expectRevert("Amount must be positive");
        token.depositGold(0);
        
        vm.expectRevert("Amount must be positive");
        token.withdrawGold(0);
        
        vm.expectRevert("Amount must be positive");
        token.mint(user, 0);
        vm.stopPrank();
        
        vm.prank(user);
        vm.expectRevert("Amount must be positive");
        token.burn(0);
    }
    
    function testZeroAddressValidation() public {
        vm.startPrank(operator);
        token.depositGold(100e18);
        
        vm.warp(block.timestamp + 2 hours);
        vm.expectRevert("Cannot mint to zero address");
        token.mint(address(0), 50e18);
        vm.stopPrank();
    }
}