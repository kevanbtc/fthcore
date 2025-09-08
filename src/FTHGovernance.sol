// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./FTHCore.sol";

/**
 * @title FTHGovernance
 * @dev Governance contract for FTH Core protocol decisions
 * Allows token holders to vote on protocol changes
 */
contract FTHGovernance is Ownable, ReentrancyGuard {
    FTHCore public immutable fthCore;
    
    struct Proposal {
        uint256 id;
        address proposer;
        string title;
        string description;
        bytes callData;
        address target;
        uint256 startTime;
        uint256 endTime;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 abstainVotes;
        bool executed;
        bool cancelled;
        mapping(address => bool) hasVoted;
        mapping(address => VoteType) votes;
    }
    
    enum VoteType { Against, For, Abstain }
    enum ProposalState { Pending, Active, Cancelled, Defeated, Succeeded, Executed }
    
    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCount;
    
    uint256 public constant VOTING_PERIOD = 7 days;
    uint256 public constant PROPOSAL_THRESHOLD = 100_000 * 1e18; // 100k tokens needed to propose
    uint256 public constant QUORUM_PERCENTAGE = 10; // 10% of supply needed for quorum
    uint256 public constant EXECUTION_DELAY = 2 days;
    
    event ProposalCreated(
        uint256 indexed proposalId,
        address indexed proposer,
        string title,
        string description,
        uint256 startTime,
        uint256 endTime
    );
    
    event VoteCast(
        uint256 indexed proposalId,
        address indexed voter,
        VoteType voteType,
        uint256 weight
    );
    
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalCancelled(uint256 indexed proposalId);
    
    constructor(address _fthCore) Ownable(msg.sender) {
        fthCore = FTHCore(_fthCore);
    }
    
    function propose(
        string memory title,
        string memory description,
        address target,
        bytes memory callData
    ) external returns (uint256) {
        require(
            fthCore.balanceOf(msg.sender) >= PROPOSAL_THRESHOLD,
            "Insufficient tokens to propose"
        );
        
        uint256 proposalId = ++proposalCount;
        Proposal storage proposal = proposals[proposalId];
        
        proposal.id = proposalId;
        proposal.proposer = msg.sender;
        proposal.title = title;
        proposal.description = description;
        proposal.callData = callData;
        proposal.target = target;
        proposal.startTime = block.timestamp;
        proposal.endTime = block.timestamp + VOTING_PERIOD;
        
        emit ProposalCreated(
            proposalId,
            msg.sender,
            title,
            description,
            proposal.startTime,
            proposal.endTime
        );
        
        return proposalId;
    }
    
    function vote(uint256 proposalId, VoteType voteType) external nonReentrant {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(block.timestamp >= proposal.startTime, "Voting not started");
        require(block.timestamp <= proposal.endTime, "Voting ended");
        require(!proposal.hasVoted[msg.sender], "Already voted");
        
        uint256 weight = fthCore.balanceOf(msg.sender);
        require(weight > 0, "No voting power");
        
        proposal.hasVoted[msg.sender] = true;
        proposal.votes[msg.sender] = voteType;
        
        if (voteType == VoteType.For) {
            proposal.forVotes += weight;
        } else if (voteType == VoteType.Against) {
            proposal.againstVotes += weight;
        } else {
            proposal.abstainVotes += weight;
        }
        
        emit VoteCast(proposalId, msg.sender, voteType, weight);
    }
    
    function execute(uint256 proposalId) external nonReentrant {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(block.timestamp > proposal.endTime + EXECUTION_DELAY, "Execution delay not met");
        require(!proposal.executed, "Already executed");
        require(!proposal.cancelled, "Proposal cancelled");
        require(getProposalState(proposalId) == ProposalState.Succeeded, "Proposal not successful");
        
        proposal.executed = true;
        
        if (proposal.target != address(0) && proposal.callData.length > 0) {
            (bool success,) = proposal.target.call(proposal.callData);
            require(success, "Execution failed");
        }
        
        emit ProposalExecuted(proposalId);
    }
    
    function cancel(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(
            msg.sender == proposal.proposer || msg.sender == owner(),
            "Not authorized to cancel"
        );
        require(!proposal.executed, "Already executed");
        require(block.timestamp <= proposal.endTime, "Voting ended");
        
        proposal.cancelled = true;
        emit ProposalCancelled(proposalId);
    }
    
    function getProposalState(uint256 proposalId) public view returns (ProposalState) {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        
        if (proposal.cancelled) return ProposalState.Cancelled;
        if (proposal.executed) return ProposalState.Executed;
        if (block.timestamp <= proposal.endTime) return ProposalState.Active;
        
        uint256 totalVotes = proposal.forVotes + proposal.againstVotes + proposal.abstainVotes;
        uint256 quorumRequired = (fthCore.totalSupply() * QUORUM_PERCENTAGE) / 100;
        
        if (totalVotes < quorumRequired) return ProposalState.Defeated;
        if (proposal.forVotes > proposal.againstVotes) return ProposalState.Succeeded;
        
        return ProposalState.Defeated;
    }
    
    function getProposalVotes(uint256 proposalId) external view returns (
        uint256 forVotes,
        uint256 againstVotes,
        uint256 abstainVotes
    ) {
        Proposal storage proposal = proposals[proposalId];
        return (proposal.forVotes, proposal.againstVotes, proposal.abstainVotes);
    }
    
    function hasVoted(uint256 proposalId, address voter) external view returns (bool) {
        return proposals[proposalId].hasVoted[voter];
    }
    
    function getVote(uint256 proposalId, address voter) external view returns (VoteType) {
        require(proposals[proposalId].hasVoted[voter], "Voter has not voted");
        return proposals[proposalId].votes[voter];
    }
}