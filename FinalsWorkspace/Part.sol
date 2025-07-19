// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

contract Part {
    enum Condition { BAD, POOR, FAIR, GOOD, MINT }

    struct TransferRecord {
        address from;
        address to;
        uint256 timestamp;
    }

    uint256 public partID;
    uint256 private partPrice; 
    string private carPart;
    string private brand;
    Condition private condition;
    bool private warrantyClaimed;
    TransferRecord[] public transferHistory;

    address public owner;
    address public autoChainAddress;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyAutoChain() {
        require(msg.sender == autoChainAddress, "Only AutoChainParts can call this");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not part owner");
        _;
    }

    constructor(uint256 _partPrice, uint256 _partID, string memory _carPart, string memory _brand, address _initialOwner) {
        require(_initialOwner != address(0), "Invalid owner");
        partID = _partID;
        partPrice = _partPrice; 
        carPart = _carPart;
        brand = _brand;
        condition = Condition.MINT;
        warrantyClaimed = false;

        owner = _initialOwner;
        transferHistory.push(TransferRecord({
            from: address(0),  
            to: _initialOwner, 
            timestamp: block.timestamp
        })); 
        autoChainAddress = msg.sender;
    }

    function updateCondition(Condition _condition) external onlyAutoChain {
        condition = _condition;
    }

    function contractTransferOwnership(address newOwner) external onlyAutoChain {
        require(newOwner != address(0), "Cannot transfer to zero address");
        emit OwnershipTransferred(owner, newOwner);

        transferHistory.push(TransferRecord({
            from: owner,
            to: newOwner,
            timestamp: block.timestamp
        })); 

        owner = newOwner;
    }

    function claimWarranty() external onlyAutoChain {
        require(!warrantyClaimed, "Already claimed");
        warrantyClaimed = true;
    }

    function getCarPart() external view onlyAutoChain returns (string memory _carPart) {
        return carPart; 
    }

    function getBrand() external view onlyAutoChain returns (string memory _brand) {
        return brand; 
    }

    function getCondition() external view onlyAutoChain returns (Condition _condition) {
        return condition; 
    }

    function getPartPrice() external view onlyAutoChain returns (uint256 _partPrice) {
        return partPrice; 
    }

    function getTransferRecord(uint256 index) external view onlyAutoChain returns (address from, address to, uint256 timestamp ) {
        require(index < transferHistory.length, "Index out of bounds");
        TransferRecord memory record = transferHistory[index];
        return (record.from, record.to, record.timestamp);
    }

    function getLatestTransaction() external view onlyAutoChain returns (uint256 latest){
        return transferHistory.length; 
    }

    function updatePartPrice(uint256 _partPrice) external onlyAutoChain {
        partPrice = _partPrice;
    }

}