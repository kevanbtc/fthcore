// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title FTHMultiSig
 * @dev Multi-signature wallet for critical FTH Core operations
 * Requires multiple signatures for sensitive operations
 */
contract FTHMultiSig is ReentrancyGuard {
    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 confirmations;
        mapping(address => bool) confirmedBy;
    }
    
    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public required; // Number of confirmations required
    
    mapping(uint256 => Transaction) public transactions;
    uint256 public transactionCount;
    
    uint256 public constant MAX_OWNERS = 10;
    
    event Submission(uint256 indexed transactionId);
    event Confirmation(address indexed sender, uint256 indexed transactionId);
    event Revocation(address indexed sender, uint256 indexed transactionId);
    event Execution(uint256 indexed transactionId);
    event ExecutionFailure(uint256 indexed transactionId);
    event OwnerAddition(address indexed owner);
    event OwnerRemoval(address indexed owner);
    event RequirementChange(uint256 required);
    
    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not an owner");
        _;
    }
    
    modifier ownerExists(address owner) {
        require(isOwner[owner], "Owner does not exist");
        _;
    }
    
    modifier ownerDoesNotExist(address owner) {
        require(!isOwner[owner], "Owner already exists");
        _;
    }
    
    modifier transactionExists(uint256 transactionId) {
        require(transactions[transactionId].to != address(0), "Transaction does not exist");
        _;
    }
    
    modifier confirmed(uint256 transactionId, address owner) {
        require(transactions[transactionId].confirmedBy[owner], "Transaction not confirmed");
        _;
    }
    
    modifier notConfirmed(uint256 transactionId, address owner) {
        require(!transactions[transactionId].confirmedBy[owner], "Transaction already confirmed");
        _;
    }
    
    modifier notExecuted(uint256 transactionId) {
        require(!transactions[transactionId].executed, "Transaction already executed");
        _;
    }
    
    modifier validRequirement(uint256 ownerCount, uint256 _required) {
        require(
            ownerCount <= MAX_OWNERS &&
            _required <= ownerCount &&
            _required != 0 &&
            ownerCount != 0,
            "Invalid requirement"
        );
        _;
    }
    
    constructor(address[] memory _owners, uint256 _required)
        validRequirement(_owners.length, _required)
    {
        for (uint256 i = 0; i < _owners.length; i++) {
            require(_owners[i] != address(0), "Invalid owner address");
            require(!isOwner[_owners[i]], "Duplicate owner");
            
            isOwner[_owners[i]] = true;
            owners.push(_owners[i]);
        }
        required = _required;
    }
    
    receive() external payable {}
    
    function submitTransaction(address to, uint256 value, bytes memory data)
        external
        onlyOwner
        returns (uint256 transactionId)
    {
        transactionId = transactionCount;
        transactions[transactionId].to = to;
        transactions[transactionId].value = value;
        transactions[transactionId].data = data;
        transactionCount++;
        
        emit Submission(transactionId);
        confirmTransaction(transactionId);
    }
    
    function confirmTransaction(uint256 transactionId)
        public
        onlyOwner
        transactionExists(transactionId)
        notConfirmed(transactionId, msg.sender)
    {
        transactions[transactionId].confirmedBy[msg.sender] = true;
        transactions[transactionId].confirmations++;
        
        emit Confirmation(msg.sender, transactionId);
        
        executeTransaction(transactionId);
    }
    
    function revokeConfirmation(uint256 transactionId)
        external
        onlyOwner
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        transactions[transactionId].confirmedBy[msg.sender] = false;
        transactions[transactionId].confirmations--;
        
        emit Revocation(msg.sender, transactionId);
    }
    
    function executeTransaction(uint256 transactionId)
        public
        onlyOwner
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        if (isConfirmed(transactionId)) {
            Transaction storage txn = transactions[transactionId];
            txn.executed = true;
            
            (bool success,) = txn.to.call{value: txn.value}(txn.data);
            if (success) {
                emit Execution(transactionId);
            } else {
                emit ExecutionFailure(transactionId);
                txn.executed = false;
            }
        }
    }
    
    function isConfirmed(uint256 transactionId) public view returns (bool) {
        return transactions[transactionId].confirmations >= required;
    }
    
    function addOwner(address owner)
        external
        onlyOwner
        ownerDoesNotExist(owner)
        validRequirement(owners.length + 1, required)
    {
        // This function must be called through a multisig transaction
        require(msg.sender == address(this), "Must be called through multisig");
        
        isOwner[owner] = true;
        owners.push(owner);
        emit OwnerAddition(owner);
    }
    
    function removeOwner(address owner) external onlyOwner ownerExists(owner) {
        // This function must be called through a multisig transaction
        require(msg.sender == address(this), "Must be called through multisig");
        
        isOwner[owner] = false;
        for (uint256 i = 0; i < owners.length - 1; i++) {
            if (owners[i] == owner) {
                owners[i] = owners[owners.length - 1];
                break;
            }
        }
        owners.pop();
        
        if (required > owners.length) {
            changeRequirement(owners.length);
        }
        
        emit OwnerRemoval(owner);
    }
    
    function replaceOwner(address owner, address newOwner)
        external
        onlyOwner
        ownerExists(owner)
        ownerDoesNotExist(newOwner)
    {
        // This function must be called through a multisig transaction
        require(msg.sender == address(this), "Must be called through multisig");
        
        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == owner) {
                owners[i] = newOwner;
                break;
            }
        }
        
        isOwner[owner] = false;
        isOwner[newOwner] = true;
        
        emit OwnerRemoval(owner);
        emit OwnerAddition(newOwner);
    }
    
    function changeRequirement(uint256 _required)
        public
        onlyOwner
        validRequirement(owners.length, _required)
    {
        // This function must be called through a multisig transaction
        require(msg.sender == address(this), "Must be called through multisig");
        
        required = _required;
        emit RequirementChange(_required);
    }
    
    function getOwners() external view returns (address[] memory) {
        return owners;
    }
    
    function getTransactionCount(bool pending, bool executed) external view returns (uint256 count) {
        for (uint256 i = 0; i < transactionCount; i++) {
            if (pending && !transactions[i].executed || executed && transactions[i].executed) {
                count++;
            }
        }
    }
    
    function getTransactionIds(uint256 from, uint256 to, bool pending, bool executed)
        external
        view
        returns (uint256[] memory _transactionIds)
    {
        uint256[] memory transactionIdsTemp = new uint256[](transactionCount);
        uint256 count = 0;
        uint256 i;
        
        for (i = 0; i < transactionCount; i++) {
            if (pending && !transactions[i].executed || executed && transactions[i].executed) {
                transactionIdsTemp[count] = i;
                count++;
            }
        }
        
        _transactionIds = new uint256[](to - from);
        for (i = from; i < to; i++) {
            _transactionIds[i - from] = transactionIdsTemp[i];
        }
    }
    
    function getConfirmationCount(uint256 transactionId) external view returns (uint256) {
        return transactions[transactionId].confirmations;
    }
    
    function getConfirmations(uint256 transactionId) external view returns (address[] memory _confirmations) {
        address[] memory confirmationsTemp = new address[](owners.length);
        uint256 count = 0;
        uint256 i;
        
        for (i = 0; i < owners.length; i++) {
            if (transactions[transactionId].confirmedBy[owners[i]]) {
                confirmationsTemp[count] = owners[i];
                count++;
            }
        }
        
        _confirmations = new address[](count);
        for (i = 0; i < count; i++) {
            _confirmations[i] = confirmationsTemp[i];
        }
    }
}