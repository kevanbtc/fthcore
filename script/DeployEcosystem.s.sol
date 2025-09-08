// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/FTHCore.sol";
import "../src/FTHGovernance.sol";
import "../src/FTHStaking.sol";
import "../src/FTHOracle.sol";
import "../src/FTHMultiSig.sol";

contract DeployFullEcosystem is Script {
    // Deployment addresses will be stored here
    address public fthCore;
    address public governance;
    address public staking;
    address public oracle;
    address public multiSig;
    
    // Configuration parameters
    uint256 public constant INITIAL_GOLD_PRICE = 60 * 1e8; // $60 per gram
    uint256 public constant STAKING_APY = 500; // 5%
    uint256 public constant MIN_STAKE = 1000 * 1e18; // 1000 FTHC
    uint256 public constant LOCK_PERIOD = 30 days;
    
    function run() external {
        vm.startBroadcast();
        
        console.log("=== FTH Core Ecosystem Deployment ===");
        console.log("Deployer:", msg.sender);
        console.log("Chain ID:", block.chainid);
        
        // Deploy core token contract
        deployFTHCore();
        
        // Deploy governance contract
        deployGovernance();
        
        // Deploy staking contract
        deployStaking();
        
        // Deploy oracle contract
        deployOracle();
        
        // Deploy multi-sig contract
        deployMultiSig();
        
        // Configure contracts
        configureContracts();
        
        // Display deployment summary
        displaySummary();
        
        vm.stopBroadcast();
    }
    
    function deployFTHCore() internal {
        console.log("\n--- Deploying FTH Core Token ---");
        fthCore = address(new FTHCore());
        console.log("FTH Core deployed at:", fthCore);
        
        FTHCore token = FTHCore(fthCore);
        console.log("Token name:", token.name());
        console.log("Token symbol:", token.symbol());
        console.log("Owner:", token.owner());
    }
    
    function deployGovernance() internal {
        console.log("\n--- Deploying Governance ---");
        governance = address(new FTHGovernance(fthCore));
        console.log("Governance deployed at:", governance);
        
        FTHGovernance gov = FTHGovernance(governance);
        console.log("Proposal threshold:", gov.PROPOSAL_THRESHOLD() / 1e18, "FTHC");
        console.log("Voting period:", gov.VOTING_PERIOD() / 1 days, "days");
        console.log("Execution delay:", gov.EXECUTION_DELAY() / 1 days, "days");
    }
    
    function deployStaking() internal {
        console.log("\n--- Deploying Staking ---");
        staking = address(new FTHStaking(fthCore));
        console.log("Staking deployed at:", staking);
        
        FTHStaking stakingContract = FTHStaking(staking);
        
        // Configure staking parameters
        stakingContract.setRewardRate(STAKING_APY);
        stakingContract.setMinimumStake(MIN_STAKE);
        stakingContract.setLockPeriod(LOCK_PERIOD);
        
        console.log("Staking APY:", STAKING_APY / 100, "%");
        console.log("Min stake:", MIN_STAKE / 1e18, "FTHC");
        console.log("Lock period:", LOCK_PERIOD / 1 days, "days");
    }
    
    function deployOracle() internal {
        console.log("\n--- Deploying Oracle ---");
        oracle = address(new FTHOracle());
        console.log("Oracle deployed at:", oracle);
        
        FTHOracle oracleContract = FTHOracle(oracle);
        console.log("Min oracles:", oracleContract.MIN_ORACLES());
        console.log("Max price age:", oracleContract.MAX_PRICE_AGE() / 1 hours, "hours");
        console.log("Update threshold:", oracleContract.updateThreshold() / 100, "%");
    }
    
    function deployMultiSig() internal {
        console.log("\n--- Deploying Multi-Sig ---");
        
        // Multi-sig owners (modify for production)
        address[] memory owners = new address[](3);
        owners[0] = msg.sender; // Deployer
        owners[1] = 0x742d35Cc6641B7D5Fafe09eE26aA3C3e82b03BaD; // Example owner 2
        owners[2] = 0x8ba1f109551bD432803012645Hac136c0c5e630c; // Example owner 3
        
        uint256 required = 2; // 2 of 3 signatures required
        
        multiSig = address(new FTHMultiSig(owners, required));
        console.log("Multi-Sig deployed at:", multiSig);
        console.log("Required signatures:", required, "of", owners.length);
    }
    
    function configureContracts() internal {
        console.log("\n--- Configuring Contracts ---");
        
        FTHCore token = FTHCore(fthCore);
        FTHOracle oracleContract = FTHOracle(oracle);
        
        // Set initial gold price
        token.updateGoldPrice(INITIAL_GOLD_PRICE);
        console.log("Initial gold price set:", INITIAL_GOLD_PRICE / 1e8, "USD/gram");
        
        // Add deployer as initial oracle
        oracleContract.addOracle(msg.sender, 10000); // 100% weight initially
        console.log("Added deployer as initial oracle");
        
        // Submit initial price to oracle
        oracleContract.submitPrice(INITIAL_GOLD_PRICE);
        console.log("Submitted initial price to oracle");
        
        // Authorize staking contract for token operations (if needed)
        // token.setAuthorized(staking, true);
    }
    
    function displaySummary() internal view {
        console.log("\n=== Deployment Summary ===");
        console.log("FTH Core Token:    ", fthCore);
        console.log("Governance:        ", governance);
        console.log("Staking:           ", staking);
        console.log("Oracle:            ", oracle);
        console.log("Multi-Sig:         ", multiSig);
        console.log("\n=== Next Steps ===");
        console.log("1. Verify contracts on block explorer");
        console.log("2. Set up additional oracle providers");
        console.log("3. Transfer ownership to multi-sig");
        console.log("4. Fund staking contract with rewards");
        console.log("5. Create initial governance proposals");
        
        if (block.chainid == 1) {
            console.log("\n⚠️  MAINNET DEPLOYMENT - Use with caution!");
        } else {
            console.log("\n✅ Testnet deployment complete");
        }
    }
}

// Separate deployment script for individual contracts
contract DeployCore is Script {
    function run() external {
        vm.startBroadcast();
        
        FTHCore token = new FTHCore();
        
        console.log("FTH Core deployed at:", address(token));
        console.log("Owner:", token.owner());
        console.log("Name:", token.name());
        console.log("Symbol:", token.symbol());
        
        vm.stopBroadcast();
    }
}

contract DeployGovernance is Script {
    function run() external {
        address fthCore = vm.envAddress("FTH_CORE_ADDRESS");
        require(fthCore != address(0), "FTH_CORE_ADDRESS not set");
        
        vm.startBroadcast();
        
        FTHGovernance governance = new FTHGovernance(fthCore);
        
        console.log("Governance deployed at:", address(governance));
        console.log("FTH Core address:", fthCore);
        
        vm.stopBroadcast();
    }
}

contract DeployStaking is Script {
    function run() external {
        address fthCore = vm.envAddress("FTH_CORE_ADDRESS");
        require(fthCore != address(0), "FTH_CORE_ADDRESS not set");
        
        vm.startBroadcast();
        
        FTHStaking staking = new FTHStaking(fthCore);
        
        console.log("Staking deployed at:", address(staking));
        console.log("FTH Core address:", fthCore);
        
        vm.stopBroadcast();
    }
}

contract DeployOracle is Script {
    function run() external {
        vm.startBroadcast();
        
        FTHOracle oracle = new FTHOracle();
        
        console.log("Oracle deployed at:", address(oracle));
        console.log("Owner:", oracle.owner());
        
        vm.stopBroadcast();
    }
}