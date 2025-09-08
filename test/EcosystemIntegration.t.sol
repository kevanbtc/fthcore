// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/FTHCore.sol";
import "../src/FTHGovernance.sol";
import "../src/FTHStaking.sol";
import "../src/FTHOracle.sol";
import "../src/FTHMultiSig.sol";

contract EcosystemIntegrationTest is Test {
    FTHCore public token;
    FTHGovernance public governance;
    FTHStaking public staking;
    FTHOracle public oracle;
    FTHMultiSig public multiSig;
    
    address public owner = address(0x123);
    address public user1 = address(0x456);
    address public user2 = address(0x789);
    address public oracle1 = address(0xabc);
    address public oracle2 = address(0xdef);
    
    function setUp() public {
        vm.startPrank(owner);
        
        // Deploy contracts
        token = new FTHCore();
        governance = new FTHGovernance(address(token));
        staking = new FTHStaking(address(token));
        oracle = new FTHOracle();
        
        address[] memory owners = new address[](3);
        owners[0] = owner;
        owners[1] = user1;
        owners[2] = user2;
        multiSig = new FTHMultiSig(owners, 2);
        
        // Setup oracles
        oracle.addOracle(oracle1, 5000); // 50% weight
        oracle.addOracle(oracle2, 5000); // 50% weight
        
        // Authorize operators
        token.setAuthorized(address(this), true);
        
        vm.stopPrank();
    }
    
    function testCompleteTokenLifecycle() public {
        vm.startPrank(owner);
        
        // 1. Deposit gold
        token.depositGold(1000e18);
        assertEq(token.goldReserves(), 1000e18);
        
        // 2. Mint tokens
        token.mint(user1, 500e18);
        assertEq(token.balanceOf(user1), 500e18);
        assertEq(token.backingRatio(), 2e18); // 200% backing
        assertTrue(token.isFullyBacked());
        
        // 3. Transfer tokens
        vm.stopPrank();
        vm.prank(user1);
        token.transfer(user2, 100e18);
        assertEq(token.balanceOf(user2), 100e18);
        assertEq(token.balanceOf(user1), 400e18);
        
        // 4. Burn tokens
        vm.prank(user2);
        token.burn(50e18);
        assertEq(token.balanceOf(user2), 50e18);
        assertEq(token.totalSupply(), 450e18);
        
        vm.stopPrank();
    }
    
    function testStakingIntegration() public {
        // Setup: mint tokens and fund reward pool
        vm.startPrank(owner);
        token.depositGold(2000e18);
        token.mint(user1, 1500e18);
        token.mint(address(staking), 500e18); // Reward pool
        staking.fundRewardPool(500e18);
        vm.stopPrank();
        
        // User stakes tokens
        vm.startPrank(user1);
        token.approve(address(staking), 1000e18);
        staking.stake(1000e18);
        
        // Check staking info
        (uint256 amount, uint256 startTime, uint256 lockExpiry, uint256 pending) = 
            staking.getStakeInfo(user1);
        assertEq(amount, 1000e18);
        assertEq(pending, 0); // No rewards yet
        
        // Fast forward time and check rewards
        vm.warp(block.timestamp + 365 days);
        uint256 rewards = staking.calculateRewards(user1);
        assertApproxEqRel(rewards, 50e18, 0.01e18); // ~5% APY
        
        // Claim rewards
        staking.claimRewards();
        assertTrue(token.balanceOf(user1) > 500e18); // Original + rewards
        
        // Unstake after lock period
        staking.unstake(1000e18);
        assertEq(token.balanceOf(user1), 1500e18 + rewards);
        
        vm.stopPrank();
    }
    
    function testGovernanceWorkflow() public {
        // Setup: distribute tokens for voting
        vm.startPrank(owner);
        token.depositGold(300000e18);
        token.mint(user1, 150000e18); // Above proposal threshold
        token.mint(user2, 100000e18);
        vm.stopPrank();
        
        // User1 creates proposal
        vm.prank(user1);
        uint256 proposalId = governance.propose(
            "Increase Staking APY",
            "Proposal to increase staking APY from 5% to 7%",
            address(staking),
            abi.encodeWithSelector(staking.setRewardRate.selector, 700)
        );
        
        // Check proposal state
        assertEq(uint(governance.getProposalState(proposalId)), uint(FTHGovernance.ProposalState.Active));
        
        // Users vote
        vm.prank(user1);
        governance.vote(proposalId, FTHGovernance.VoteType.For);
        
        vm.prank(user2);
        governance.vote(proposalId, FTHGovernance.VoteType.For);
        
        // Fast forward past voting period
        vm.warp(block.timestamp + 8 days);
        assertEq(uint(governance.getProposalState(proposalId)), uint(FTHGovernance.ProposalState.Succeeded));
        
        // Execute after delay
        vm.warp(block.timestamp + 3 days);
        vm.prank(user1);
        governance.execute(proposalId);
        
        // Verify execution
        assertEq(staking.getAPY(), 700); // 7%
        assertEq(uint(governance.getProposalState(proposalId)), uint(FTHGovernance.ProposalState.Executed));
    }
    
    function testOracleSystem() public {
        vm.startPrank(owner);
        
        // Submit prices from oracles
        vm.startPrank(oracle1);
        oracle.submitPrice(60e8); // $60/gram
        vm.stopPrank();
        
        vm.startPrank(oracle2);
        oracle.submitPrice(62e8); // $62/gram
        vm.stopPrank();
        
        // Check aggregated price
        (uint256 price, uint256 timestamp, bool isValid) = oracle.getLatestPrice();
        assertTrue(isValid);
        assertEq(price, 61e8); // Average of 60 and 62
        
        // Update token price from oracle
        vm.prank(owner);
        token.updateGoldPrice(price);
        assertEq(token.goldPriceUSD(), 61e8);
        
        vm.stopPrank();
    }
    
    function testMultiSigOperations() public {
        // Submit transaction to change token authorization
        vm.prank(owner);
        bytes memory data = abi.encodeWithSelector(
            token.setAuthorized.selector,
            user1,
            true
        );
        uint256 txId = multiSig.submitTransaction(address(token), 0, data);
        
        // Second owner confirms
        vm.prank(user1);
        multiSig.confirmTransaction(txId);
        
        // Check if transaction is confirmed and executed
        assertTrue(multiSig.isConfirmed(txId));
        assertTrue(token.authorized(user1));
    }
    
    function testEmergencyProcedures() public {
        // Mint some tokens first
        vm.startPrank(owner);
        token.depositGold(1000e18);
        token.mint(user1, 500e18);
        
        // Activate emergency mode
        token.toggleEmergencyMode();
        assertTrue(token.emergencyMode());
        assertTrue(token.paused());
        
        // Normal operations should fail
        vm.expectRevert();
        token.mint(user2, 100e18);
        
        // User transfers should fail when paused
        vm.stopPrank();
        vm.prank(user1);
        vm.expectRevert();
        token.transfer(user2, 100e18);
        
        // Only owner can operate in emergency mode
        vm.prank(owner);
        token.emergencyUnpause();
        assertFalse(token.paused());
        
        vm.stopPrank();
    }
    
    function testAdvancedFeatures() public {
        vm.startPrank(owner);
        
        // Test rate limiting
        token.setOperationCooldown(1 hours);
        token.depositGold(1000e18);
        
        // Second operation within cooldown should fail
        vm.expectRevert("Operation too frequent");
        token.depositGold(500e18);
        
        // Fast forward past cooldown
        vm.warp(block.timestamp + 2 hours);
        token.depositGold(500e18); // Should succeed
        
        // Test maximum supply limit
        uint256 maxSupply = token.MAX_SUPPLY();
        vm.expectRevert("Would exceed max supply");
        token.mint(user1, maxSupply + 1);
        
        // Test backing ratio maintenance
        token.mint(user1, 1000e18);
        vm.expectRevert("Would break backing ratio");
        token.withdrawGold(1000e18); // Would leave insufficient backing
        
        vm.stopPrank();
    }
    
    function testCrossContractInteractions() public {
        // Setup initial state
        vm.startPrank(owner);
        token.depositGold(2000e18);
        token.mint(user1, 1000e18);
        vm.stopPrank();
        
        // User stakes tokens
        vm.startPrank(user1);
        token.approve(address(staking), 1000e18);
        staking.stake(1000e18);
        vm.stopPrank();
        
        // Create governance proposal to change staking parameters
        vm.prank(user1);
        uint256 proposalId = governance.propose(
            "Update Minimum Stake",
            "Reduce minimum stake to 500 FTHC",
            address(staking),
            abi.encodeWithSelector(staking.setMinimumStake.selector, 500e18)
        );
        
        // Vote with staked tokens (voting power should still work)
        vm.prank(user1);
        governance.vote(proposalId, FTHGovernance.VoteType.For);
        
        // Verify voting power is recognized
        (uint256 forVotes,,) = governance.getProposalVotes(proposalId);
        assertEq(forVotes, 1000e18); // Staked amount counted for voting
    }
}