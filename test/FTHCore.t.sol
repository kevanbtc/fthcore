// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/FTHCore.sol";

contract FTHCoreTest is Test {
    FTHCore public token;
    address public owner = address(0x123);
    address public user = address(0x456);
    
    function setUp() public {
        vm.startPrank(owner);
        token = new FTHCore();
        vm.stopPrank();
    }
    
    function testInitialState() public view {
        assertEq(token.name(), "FTH Core Gold");
        assertEq(token.symbol(), "FTHC");
        assertEq(token.goldReserves(), 0);
        assertEq(token.totalSupply(), 0);
        assertTrue(token.authorized(owner));
        assertTrue(token.isFullyBacked());
    }
    
    function testDepositGold() public {
        vm.prank(owner);
        token.depositGold(100e18);
        
        assertEq(token.goldReserves(), 100e18);
    }
    
    function testMintWithBacking() public {
        vm.startPrank(owner);
        token.depositGold(100e18);
        token.mint(user, 50e18);
        vm.stopPrank();
        
        assertEq(token.balanceOf(user), 50e18);
        assertEq(token.totalSupply(), 50e18);
        assertTrue(token.isFullyBacked());
    }
    
    function testMintWithoutBacking() public {
        vm.startPrank(owner);
        vm.expectRevert("Insufficient gold backing");
        token.mint(user, 50e18);
        vm.stopPrank();
    }
    
    function testBurn() public {
        vm.startPrank(owner);
        token.depositGold(100e18);
        token.mint(user, 50e18);
        vm.stopPrank();
        
        vm.prank(user);
        token.burn(25e18);
        
        assertEq(token.balanceOf(user), 25e18);
        assertEq(token.totalSupply(), 25e18);
    }
    
    function testWithdrawGold() public {
        vm.startPrank(owner);
        token.depositGold(100e18);
        token.mint(user, 50e18);
        token.withdrawGold(25e18);
        vm.stopPrank();
        
        assertEq(token.goldReserves(), 75e18);
        assertTrue(token.isFullyBacked());
    }
    
    function testWithdrawTooMuchGold() public {
        vm.startPrank(owner);
        token.depositGold(100e18);
        token.mint(user, 50e18);
        vm.expectRevert("Would break backing ratio");
        token.withdrawGold(60e18);
        vm.stopPrank();
    }
    
    function testBackingRatio() public {
        vm.startPrank(owner);
        token.depositGold(100e18);
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
        vm.stopPrank();
    }
}